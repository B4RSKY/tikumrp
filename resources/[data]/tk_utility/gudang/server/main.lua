local Config = require 'gudang.shared.config'
local QBCore = exports['qb-core']:GetCoreObject()

local function now() return os.time() end

local function getLicense(src)
    local id = QBCore.Functions.GetIdentifier(src, 'steam')
    if not id then
        local p = QBCore.Functions.GetPlayer(src)
        id = p and p.PlayerData.citizenid
    end
    return id
end

local function sanitizeId(s) return s:gsub('%W', ''):lower() end
local function stashId(license, locKey) return ('gudang_%s_%s'):format(locKey, sanitizeId(license)) end
local function graceUntil(expireAt) return expireAt + (Config.GracePeriod or 259200) end

local function isAdmin(src)
    return QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')
end

local function registerStash(id, label, slots, weight, owner)
    exports.ox_inventory:RegisterStash(id, label, slots, weight, owner)
end

local function sendWebhook(title, desc, color, fields)
    local url = "https://discord.com/api/webhooks/1404412532180910161/szlu0eAuRjG7dTjkvWaLHb5YFSpBuhEUi58w06J2HcZezFPiZtPl9jhAQmN_qfrpnU6-"
    if not url or url == '' then return end
    local embed = {
        {  
            title = title,
            description = desc,
            color = color or 5814783, -- ungu
            fields = fields,
            footer = { text = "TIKUMRP Logs • "..os.date("%a, %d %b %y at %H:%M%p"), },
        }
    }
    PerformHttpRequest(url, function() end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
end

AddEventHandler('onServerResourceStart', function(resName)
    local me = GetCurrentResourceName()
    if resName ~= me and resName ~= 'ox_inventory' then return end

    -- MySQL.query([[
    --     CREATE TABLE IF NOT EXISTS sky_gudang (
    --     id INT AUTO_INCREMENT PRIMARY KEY,
    --     owner VARCHAR(64) NOT NULL,
    --     location VARCHAR(32) NOT NULL,
    --     weight INT NOT NULL,
    --     slots INT NOT NULL,
    --     expire_at INT NOT NULL,
    --     stash_id VARCHAR(96) NOT NULL UNIQUE,
    --     warned TINYINT NOT NULL DEFAULT 0,
    --     autobill_key VARCHAR(8) NULL,
    --     autobill_tried TINYINT NOT NULL DEFAULT 0
    --     );
    -- ]])

    -- MySQL.query('CREATE INDEX IF NOT EXISTS idx_gudang_owner ON sky_gudang(owner);')
    -- MySQL.query('CREATE INDEX IF NOT EXISTS idx_gudang_expire ON sky_gudang(expire_at);')
    -- MySQL.query('CREATE UNIQUE INDEX IF NOT EXISTS uniq_gudang_owner_loc ON sky_gudang(owner, location);')
    -- MySQL.query('ALTER TABLE sky_gudang ADD COLUMN IF NOT EXISTS autobill_key VARCHAR(8) NULL;')
    -- MySQL.query('ALTER TABLE sky_gudang ADD COLUMN IF NOT EXISTS autobill_tried TINYINT NOT NULL DEFAULT 0;')

    local rows = MySQL.query.await(
        'SELECT owner, location, weight, slots, stash_id, expire_at FROM sky_gudang WHERE (expire_at + ?) > ?',
        { Config.GracePeriod or 259200, now() }
    ) or {}
    for _, r in ipairs(rows) do
        local loc = Config.Lokasi[r.location]
        registerStash(r.stash_id, ('%s'):format(loc and loc.label or r.location), r.slots, r.weight, r.owner)
    end
end)

local function housekeeping()
    local t = now()
    local warnWindow = t + (24 * 60 * 60) -- H-1 sebelum expired

    local toWarn = MySQL.query.await('SELECT id, owner, location, expire_at FROM sky_gudang WHERE warned = 0 AND expire_at BETWEEN ? AND ?', { t, warnWindow }) or {}
    for _, w in ipairs(toWarn) do
        for _, src in ipairs(QBCore.Functions.GetPlayers()) do
        if getLicense(src) == w.owner then
            local sisaJam = math.max(0, math.floor((w.expire_at - t) / 3600))
            lib.notify(src, {
              title = 'Sewa Gudang',
              description = ('Gudang %s akan kadaluarsa dalam %d jam. Aktifkan auto-billing atau perpanjang!'):format(w.location, sisaJam),
              type = 'warning'
            })
            break
        end
        end
        MySQL.update.await('UPDATE sky_gudang SET warned = 1 WHERE id = ?', { w.id })
    end

    local needBill = MySQL.query.await([[
        SELECT id, owner, location, weight, slots, expire_at, stash_id, autobill_key, autobill_tried
        FROM sky_gudang
        WHERE expire_at <= ? AND (expire_at + ?) > ? AND autobill_key IS NOT NULL AND autobill_tried = 0
    ]], { t, Config.GracePeriod or 259200, t }) or {}

    for _, w in ipairs(needBill) do
        local plan = Config.RentOptions[w.autobill_key]
        local price = plan and plan.harga
        local duration = plan and plan.duration
        if not price or not duration then
            MySQL.update.await('UPDATE sky_gudang SET autobill_key = NULL WHERE id = ?', { w.id })
        else
            local targetSrc
            for _, s in ipairs(QBCore.Functions.GetPlayers()) do
                if getLicense(s) == w.owner then targetSrc = s break end
            end
            local Player = targetSrc and QBCore.Functions.GetPlayer(targetSrc) or QBCore.Functions.GetOfflinePlayerByCitizenId(w.owner) -- fallback offline
            local success = false

            if Player and Player.Functions then
                success = Player.Functions.RemoveMoney('bank', price)
            end

            if success then
                local base = math.max(t, w.expire_at)
                local newExpire = base + duration
                MySQL.update.await('UPDATE sky_gudang SET expire_at = ?, warned = 0, autobill_tried = 0 WHERE id = ?', { newExpire, w.id })

                if targetSrc then
                    lib.notify(targetSrc, { title = 'Auto-Billing Gudang', description = ('Berhasil perpanjang %s otomatis.'):format(plan.label), type = 'success' })
                end

                sendWebhook('Auto-Billing Sukses', ('Lokasi: %s\nOwner: %s\nDurasi: %s\nHarga: $%d'):format(w.location, w.owner, plan.label, price), 4437377)
            else
                MySQL.update.await('UPDATE sky_gudang SET autobill_tried = 1 WHERE id = ?', { w.id })
                if targetSrc then
                    lib.notify(targetSrc, { title = 'Auto-Billing Gudang Gagal', description = 'Saldo tidak cukup. Anda masih punya 3 hari masa tenggang.', type = 'error' })
                end
                sendWebhook('Auto-Billing Gagal', ('Lokasi: %s\nOwner: %s\nDurasi: %s\nHarga: $%d'):format(w.location, w.owner, plan.label, price or -1), 15548997)
            end
        end
    end

    local expired = MySQL.query.await('SELECT id, stash_id, owner, location FROM sky_gudang WHERE (expire_at + ?) <= ?', { Config.GracePeriod or 259200, t }) or {}
    for _, e in ipairs(expired) do
        exports.ox_inventory:ClearInventory(e.stash_id)
        MySQL.query.await('DELETE FROM sky_gudang WHERE id = ?', { e.id })
        sendWebhook('Hapus Gudang (Lewat Grace)', ('Lokasi: %s\nOwner: %s'):format(e.location, e.owner), 15158332)
    end

    SetTimeout(60 * 60 * 1000, housekeeping)
end

SetTimeout(60 * 60 * 1000, housekeeping)

lib.callback.register('sky-gudang:server:getInfo', function(source, locationKey)
    if type(locationKey) ~= 'string' then return nil end
    local license = getLicense(source)
    local row = MySQL.single.await(
      'SELECT location, weight, slots, expire_at, stash_id, autobill_key FROM sky_gudang WHERE owner = ? AND location = ?',
      { license, locationKey }
    )
    if not row then return nil end
    row.grace_until = graceUntil(row.expire_at)
    return row
end)

RegisterNetEvent('sky-gudang:server:rent', function(locationKey, rentKey)
    local src = source
    local license = getLicense(src)
    local locCfg = Config.Lokasi[locationKey]
    local rent   = Config.RentOptions[rentKey]
    local price  = rent and rent.harga
    if not locCfg or not rent or not price then return end

    local existing = MySQL.single.await('SELECT id, expire_at FROM sky_gudang WHERE owner = ? AND location = ?', { license, locationKey })
    if existing and (existing.expire_at + (Config.GracePeriod or 259200)) > now() then
        return lib.notify(src, { title = 'Gagal', description = 'Masih ada data gudang (aktif/tenggang) di lokasi ini.', type = 'error' })
    elseif existing then
        MySQL.query.await('DELETE FROM sky_gudang WHERE id = ?', { existing.id })
    end

    local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
    if not Player.Functions.RemoveMoney('bank', price) then
        return lib.notify(src, { title = 'Gagal', description = 'Saldo bank tidak cukup.', type = 'error' })
    end

    local expireAt = now() + rent.duration
    local id = stashId(license, locationKey)

    MySQL.insert.await([[
        INSERT INTO sky_gudang (owner, location, weight, slots, expire_at, stash_id, warned, autobill_key, autobill_tried)
        VALUES (?, ?, ?, ?, ?, ?, 0, NULL, 0)
    ]], { license, locationKey, locCfg.defaultWeight, locCfg.defaultSlots, expireAt, id })

    registerStash(id, ('%s'):format(locCfg.label), locCfg.defaultSlots, locCfg.defaultWeight, license)
    lib.notify(src, { title = 'Sewa Gudang', description = ('Berhasil sewa di %s selama %s.'):format(locCfg.label, rent.label), type = 'success' })

    sendWebhook('Sewa Gudang', ('Lokasi: %s\nOwner: %s\nDurasi: %s\nHarga: $%d'):format(locationKey, license, rent.label, price), 3447003)
end)

RegisterNetEvent('sky-gudang:server:extend', function(locationKey, rentKey)
    local src = source
    local license = getLicense(src)
    local rent   = Config.RentOptions[rentKey]
    local price  = rent and rent.harga
    if not Config.Lokasi[locationKey] or not rent or not price then return end

    local row = MySQL.single.await('SELECT id, expire_at, weight, slots, stash_id FROM sky_gudang WHERE owner = ? AND location = ?', { license, locationKey })
    if not row then
        return lib.notify(src, { title = 'Gagal', description = 'Tidak ada data gudang di lokasi ini.', type = 'error' })
    end
    if now() > graceUntil(row.expire_at) then
        return lib.notify(src, { title = 'Gagal', description = 'Masa tenggang berakhir. Sewa baru diperlukan.', type = 'error' })
    end

    local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
    if not Player.Functions.RemoveMoney('bank', price) then
        return lib.notify(src, { title = 'Gagal', description = 'Saldo bank tidak cukup.', type = 'error' })
    end

    local base = math.max(now(), row.expire_at)
    local newExpire = base + rent.duration
    MySQL.update.await('UPDATE sky_gudang SET expire_at = ?, warned = 0, autobill_tried = 0 WHERE id = ?', { newExpire, row.id })

    local loc = Config.Lokasi[locationKey]
    registerStash(row.stash_id, ('%s'):format(loc.label), row.slots, row.weight, license)

    lib.notify(src, { title = 'Perpanjangan', description = ('Berhasil tambah %s.'):format(rent.label), type = 'success' })
    sendWebhook('Perpanjang Sewa', ('Lokasi: %s\nOwner: %s\nDurasi: %s\nHarga: $%d'):format(locationKey, license, rent.label, price), 3447003)
end)

RegisterNetEvent('sky-gudang:server:upgrade', function(locationKey, planKey)
    local src = source
    local license = getLicense(src)
    local locCfg = Config.Lokasi[locationKey]
    local plan   = Config.UpgradePlans[planKey]
    if not locCfg or not plan then return end

    local row = MySQL.single.await('SELECT id, expire_at, weight, slots, stash_id FROM sky_gudang WHERE owner = ? AND location = ?', { license, locationKey })
    if not row then
        return lib.notify(src, { title = 'Gagal', description = 'Belum punya gudang di lokasi ini.', type = 'error' })
    end

    if now() >= row.expire_at then
        return lib.notify(src, { title = 'Gagal', description = 'Sewa kadaluarsa. Perpanjang dulu sebelum upgrade.', type = 'error' })
    end

    local price = plan.harga or 0
    local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
    if price > 0 and not Player.Functions.RemoveMoney('bank', price) then
        return lib.notify(src, { title = 'Gagal', description = 'Saldo bank tidak cukup untuk upgrade.', type = 'error' })
    end

    local newWeight = (row.weight or 0) + (plan.addWeight or 0)
    local newSlots  = (row.slots or 0)  + (plan.addSlots or 0)
    MySQL.update.await('UPDATE sky_gudang SET weight = ?, slots = ? WHERE id = ?', { newWeight, newSlots, row.id })

    registerStash(row.stash_id, ('%s'):format(locCfg.label), newSlots, newWeight, license)
    lib.notify(src, { title = 'Upgrade Gudang', description = ('Kapasitas jadi %d slots / %d kg'):format(newSlots, math.floor(newWeight/1000)), type = 'success' })

    sendWebhook('Upgrade Gudang', ('Lokasi: %s\nOwner: %s\nPaket: %s\nHarga: $%d'):format(locationKey, license, plan.label, price), 15844367)
end)

RegisterNetEvent('sky-gudang:server:setAutobill', function(locationKey, rentKeyOrFalse)
    local src = source
    local license = getLicense(src)
    if not Config.Lokasi[locationKey] then return end

    local row = MySQL.single.await('SELECT id FROM sky_gudang WHERE owner = ? AND location = ?', { license, locationKey })
    if not row then
        return lib.notify(src, { title = 'Gagal', description = 'Tidak ada data gudang untuk diatur.', type = 'error' })
    end

    local key = rentKeyOrFalse
    if key ~= false then
        if not Config.RentOptions[key] then
        return lib.notify(src, { title = 'Gagal', description = 'Paket auto-billing tidak valid.', type = 'error' })
        end
    end

    MySQL.update.await('UPDATE sky_gudang SET autobill_key = ?, autobill_tried = 0 WHERE id = ?', { key or nil, row.id })
    if key == false then
        lib.notify(src, { title = 'Auto-Billing Gudang', description = 'Auto-billing dimatikan.', type = 'inform' })
        sendWebhook('Auto-Billing Dimatikan', ('Lokasi: %s\nOwner: %s'):format(locationKey, license), 15158332)
    else
        lib.notify(src, { title = 'Auto-Billing Gudang', description = ('Diaktifkan dengan paket: %s'):format(Config.RentOptions[key].label), type = 'success' })
        sendWebhook('Auto-Billing Diaktifkan', ('Lokasi: %s\nOwner: %s\nPaket: %s'):format(locationKey, license, Config.RentOptions[key].label), 4437377)
    end
end)

-- ===================== Admin Commands =====================
RegisterCommand('gudang_extend', function(src, args)
    if src ~= 0 and not isAdmin(src) then return end
    local target = tonumber(args[1]); local loc = args[2]; local rentKey = args[3]
    if not target or not loc or not rentKey or not Config.RentOptions[rentKey] then
        if src ~= 0 then TriggerClientEvent('QBCore:Notify', src, 'Usage: /gudang_extend <playerId> <lokasiKey> <1w|2w|1m>', 'error') end
        return
    end
    local Player = QBCore.Functions.GetPlayer(target); if not Player then return end
    local license = getLicense(target)

    local row = MySQL.single.await('SELECT id, expire_at, weight, slots, stash_id FROM sky_gudang WHERE owner = ? AND location = ?', { license, loc })
    if not row then if src ~= 0 then TriggerClientEvent('QBCore:Notify', src, 'Tidak ada data gudang pemain di lokasi tsb.', 'error') end return end

    local base = math.max(now(), row.expire_at)
    local newExpire = base + Config.RentOptions[rentKey].duration
    MySQL.update.await('UPDATE sky_gudang SET expire_at = ?, warned = 0, autobill_tried = 0 WHERE id = ?', { newExpire, row.id })

    local locCfg = Config.Lokasi[loc]
    registerStash(row.stash_id, ('%s'):format(locCfg.label), row.slots, row.weight, license)

    TriggerClientEvent('QBCore:Notify', target, ('Admin memperpanjang sewa: %s'):format(Config.RentOptions[rentKey].label), 'success')
    if src ~= 0 then TriggerClientEvent('QBCore:Notify', src, 'Perpanjang paksa berhasil.', 'success') end

    sendWebhook('ADMIN: Perpanjang Paksa', ('Lokasi: %s\nOwner: %s\nDurasi: %s\nBy: %s'):format(loc, license, Config.RentOptions[rentKey].label, tostring(src)), 16776960)
end)

RegisterCommand('gudang_refund', function(src, args)
    if src ~= 0 and not isAdmin(src) then return end
    local target = tonumber(args[1]); local amount = tonumber(args[2] or '0')
    if not target or not amount or amount <= 0 then
        if src ~= 0 then TriggerClientEvent('QBCore:Notify', src, 'Usage: /gudang_refund <playerId> <amount> <reason...>', 'error') end
        return
    end
    local reason = table.concat(args, ' ', 3)
    local Player = QBCore.Functions.GetPlayer(target); if not Player then return end

    Player.Functions.AddMoney('bank', amount, reason ~= '' and reason or 'warehouse_refund')
    TriggerClientEvent('QBCore:Notify', target, ('Refund $%d diterima. %s'):format(amount, reason or ''), 'success')
    if src ~= 0 then TriggerClientEvent('QBCore:Notify', src, 'Refund dikirim.', 'success') end

    sendWebhook('ADMIN: Refund', ('Penerima: %s\nAmount: $%d\nReason: %s\nBy: %s'):format(Player.PlayerData.license or Player.PlayerData.citizenid, amount, reason, tostring(src)), 16776960)
end)