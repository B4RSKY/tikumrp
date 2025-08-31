local Config = require 'vipsystem.shared.config'
local Vs = Config.VipSystem
local QBCore = exports['qb-core']:GetCoreObject()
local TZ = '+07:00'

local function getIdentifier(src, typ)
    if not src then return nil end
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        if v:find(typ..':', 1, true) == 1 then
            return v
        end
    end
    return nil
end

local function getSteamHex(src)
    return getIdentifier(src, 'steam')
end

local function getLicense(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.license then
        return Player.PlayerData.license
    end
    return getIdentifier(src, 'license') or getIdentifier(src, 'license2')
end

local function isAuthedAdmin(src)
    local steam = getSteamHex(src)
    if not steam then return false end
    for _, hex in ipairs(Vs.AdminSteam or {}) do
        if hex == steam then return true end
    end
    return false
end

local function nowUtcSec()
    return os.time(os.date('!*t'))
end

local _vipTimerGen = {}
local function cleanupExpiredFor(license)
    if not license then return 0 end
    return MySQL.update.await(([[DELETE FROM %s WHERE identifier = ? AND expires_at <= UTC_TIMESTAMP()]])
        :format(Vs.SQL.vipTable), { license }) or 0
end

local function scheduleNextExpiryRefresh(src)
    local license = getLicense(src)
    if not license then return end

    -- cari expiry paling dekat untuk player ini
    local row = MySQL.single.await(([[SELECT UNIX_TIMESTAMP(expires_at) AS exp
        FROM %s WHERE identifier = ? AND expires_at > UTC_TIMESTAMP()
        ORDER BY expires_at ASC LIMIT 1]])
        :format(Vs.SQL.vipTable), { license })

    if not row or not row.exp then return end
    local delayMs = math.max(0, (tonumber(row.exp) - nowUtcSec() + 1) * 1000)
    local gen = (_vipTimerGen[src] or 0) + 1
    _vipTimerGen[src] = gen

    SetTimeout(delayMs, function()
        -- jika sudah ada timer baru, abaikan yang lama
        if _vipTimerGen[src] ~= gen then return end
        -- bersihkan yang lewat waktu, lalu refresh statebag
        cleanupExpiredFor(license)
        refreshPlayerVip(src)
        -- lanjut jadwalkan lagi untuk expiry berikutnya (jika ada)
        scheduleNextExpiryRefresh(src)
    end)
end

local function sendDiscord(title, fields)
    local hook = "https://discord.com/api/webhooks/1410615927887888475/Dd5wPJ8YZ2o1FFgDYsPTU9mdrkFx4GvM1lWtDcOWhOWaQgN38IRgGePVpqJpnrZkXDAR"
    local embedFields = {}
    for k, v in pairs(fields or {}) do
        embedFields[#embedFields+1] = { name = tostring(k), value = tostring(v), inline = true }
    end
    local payload = json.encode({
        embeds = {{
            title = title,
            color = 0x8A2BE2,
            fields = embedFields,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }}
    })
    PerformHttpRequest(hook, function() end, 'POST', payload, {['Content-Type'] = 'application/json'})
end

local function fetchActiveVipMap(license)
    if not license then return {} end
    local rows = MySQL.query.await(([[SELECT jenis, UNIX_TIMESTAMP(expires_at) AS exp
        FROM %s WHERE identifier = ? AND expires_at > UTC_TIMESTAMP()]])
        :format(Vs.SQL.vipTable), { license })
    local map = {}
    for _, r in ipairs(rows or {}) do
        map[tonumber(r.jenis)] = tonumber(r.exp)
    end
    return map
end

local function setPlayerVipStatebag(src, vipMap)
    local p = Player(src)
    if p and p.state then
        p.state:set('tk_vip', vipMap or {}, true)
    end
end

local function refreshPlayerVip(src)
    local license = getLicense(src)
    if not license then setPlayerVipStatebag(src, {}) return end
    local vipMap = fetchActiveVipMap(license)
    setPlayerVipStatebag(src, vipMap)
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(PlayerObj)
    local src = type(PlayerObj) == 'table' and PlayerObj.PlayerData and PlayerObj.PlayerData.source or PlayerObj
    if not src then return end

    local license = getLicense(src)
    if license then
        -- bersihkan yang sudah expired untuk pemain ini
        cleanupExpiredFor(license)
    end

    refreshPlayerVip(src)
    scheduleNextExpiryRefresh(src)

    -- Notifikasi kadaluarsa: pakai detik agar tidak muncul "0 hari" menipu
    if license and Vs.ExpiryWarnDays and Vs.ExpiryWarnDays > 0 then
        local rows = MySQL.query.await(([[SELECT jenis,
                 TIMESTAMPDIFF(SECOND, UTC_TIMESTAMP(), expires_at) AS sec_left
            FROM %s
            WHERE identifier = ? AND expires_at > UTC_TIMESTAMP()]])
            :format(Vs.SQL.vipTable), { license })

        for _, r in ipairs(rows or {}) do
            local s = tonumber(r.sec_left) or 0
            if s <= 0 then
                -- ini hampir gak kejadian karena WHERE > UTC_TIMESTAMP(), tapi jaga-jaga
                cleanupExpiredFor(license)
                refreshPlayerVip(src)
            else
                local days = math.floor(s / 86400)
                if days >= 1 and days <= Vs.ExpiryWarnDays then
                    TriggerClientEvent('ox_lib:notify', src, {
                        type='inform',
                        description = ('VIP %s sisa %d hari'):format(Vs.VipJenis[tonumber(r.jenis)] or r.jenis, days)
                    })
                elseif days < 1 then
                    -- tampilkan jam/menit kalau < 1 hari
                    local hrs = math.floor((s % 86400) / 3600)
                    local mins = math.floor((s % 3600) / 60)
                    if hrs > 0 or mins > 0 then
                        TriggerClientEvent('ox_lib:notify', src, {
                            type='inform',
                            description = ('VIP %s sisa %dj %dm'):format(Vs.VipJenis[tonumber(r.jenis)] or r.jenis, hrs, mins)
                        })
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('tk_vip:server:refresh', function()
    local src = source
    refreshPlayerVip(src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local p = Player(src)
    if p and p.state then
        p.state:set('tk_vip', {}, true)
    end
end)

RegisterCommand('vipinfo', function(src)
    if src <= 0 then return end
    local license = getLicense(src)
    if not license then
        TriggerClientEvent('ox_lib:notify', src, { type='error', description='Tidak ditemukan identifier.' })
        return
    end

    -- bersihkan expired lalu tampilkan
    cleanupExpiredFor(license)

    local rows = MySQL.query.await(([[SELECT jenis,
            DATE_FORMAT(CONVERT_TZ(expires_at,'+00:00','%s'), '%%Y-%%m-%%d %%H:%%i:%%s') AS expiry_wib,
            TIMESTAMPDIFF(SECOND, UTC_TIMESTAMP(), expires_at) AS sec_left
        FROM %s
        WHERE identifier = ? AND expires_at > UTC_TIMESTAMP()
        ORDER BY expires_at DESC]]):format(TZ, Vs.SQL.vipTable), { license })

        if not rows or #rows == 0 then
            TriggerClientEvent('ox_lib:notify', src, { type='inform', description='Kamu tidak memiliki VIP aktif.' })
            return
        end

    for _, r in ipairs(rows) do
        local s = tonumber(r.sec_left) or 0
        local expiry = r.expiry_wib or '-'
        local msg
        if s >= 86400 then
            msg = ('VIP %s aktif s/d %s WIB (%d hari lagi)')
                :format(Vs.VipJenis[tonumber(r.jenis)] or r.jenis, expiry, math.floor(s/86400))
        else
            local h = math.floor((s % 86400) / 3600)
            local m = math.floor((s % 3600) / 60)
            msg = ('VIP %s aktif s/d %s WIB (%dj %dm lagi)')
                :format(Vs.VipJenis[tonumber(r.jenis)] or r.jenis, expiry, h, m)
        end
        TriggerClientEvent('ox_lib:notify', src, { type='success', description=msg })
    end
end, false)

RegisterCommand('vipclean', function(src)
    if src > 0 and not isAuthedAdmin(src) then return end
    local affected = MySQL.update.await(([[DELETE FROM %s WHERE expires_at <= UTC_TIMESTAMP()]])
        :format(Vs.SQL.vipTable), {})
    if src > 0 then
        TriggerClientEvent('ox_lib:notify', src, { type='success', description=('Hapus %d VIP expired'):format(affected or 0) })
    else
        print(('[tk_vip] vipclean removed %d rows'):format(affected or 0))
    end
end)

exports('getVip', function(srcId)
    if not srcId then return false end

    local p = Player(srcId)
    if p and p.state then
        local map = p.state.tk_vip
        if type(map) == 'table' and next(map) ~= nil then
            return true
        end
    end

    local license = getLicense(srcId)
    if not license then return false end
    local row = MySQL.single.await(([[SELECT 1 FROM %s WHERE identifier = ? AND expires_at > UTC_TIMESTAMP() LIMIT 1]])
        :format(Vs.SQL.vipTable), { license })
    return row ~= nil
end)

exports('getVipJenis', function(srcId, jenis)
    if not srcId or not jenis then return false end
    local p = Player(srcId)
    if p and p.state then
        local map = p.state.tk_vip
        if type(map) == 'table' and map[tonumber(jenis)] ~= nil then
            return true
        end
    end

    local license = getLicense(srcId)
    if not license then return false end
    local row = MySQL.single.await(([[SELECT 1 FROM %s WHERE identifier = ? AND jenis = ? AND expires_at > UTC_TIMESTAMP() LIMIT 1]])
        :format(Vs.SQL.vipTable), { license, jenis })
    return row ~= nil
end)

local redeemCooldown = {}
RegisterCommand('aktifvip', function(src, args)
    if src <= 0 then return end
    local code = (args[1] or ''):upper()
    if code == '' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Format: /aktifvip <kode>' })
        return
    end

    local nowU = os.time()
    if (nowU - (redeemCooldown[src] or 0)) < 3 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Terlalu cepat, coba lagi...' })
        return
    end
    redeemCooldown[src] = nowU

    local row = MySQL.single.await(([[SELECT code, jenis, duration_seconds, used_by, intended_identifier
        FROM %s WHERE code = ?]]):format(Vs.SQL.codesTable), { code })
    if not row then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Kode tidak ditemukan.' })
        return
    end
    if row.used_by and row.used_by ~= '' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Kode sudah digunakan.' })
        return
    end

    local license = getLicense(src)
    if Vs.LockCodeToIdentifier and row.intended_identifier and row.intended_identifier ~= license then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Kode ini tidak ditujukan untuk akunmu.' })
        return
    end

    local jenis     = tonumber(row.jenis)
    local durSec    = tonumber(row.duration_seconds)
    local playerName= GetPlayerName(src) or ('ID '..src)
    local steam     = getSteamHex(src) or 'unknown'

    MySQL.prepare.await(([[INSERT INTO %s (identifier, jenis, expires_at)
VALUES (?, ?, DATE_ADD(UTC_TIMESTAMP(), INTERVAL ? SECOND))
ON DUPLICATE KEY UPDATE
  expires_at = DATE_ADD(GREATEST(expires_at, UTC_TIMESTAMP()), INTERVAL ? SECOND)]])
        :format(Vs.SQL.vipTable), { license, jenis, durSec, durSec })

        local newExpiryWIB = MySQL.scalar.await(
    ([[SELECT DATE_FORMAT(CONVERT_TZ(expires_at,'+00:00','%s'), '%%Y-%%m-%%d %%H:%%i:%%s')
        FROM %s WHERE identifier = ? AND jenis = ?]]):format(TZ, Vs.SQL.vipTable),
    { license, jenis }
)

    MySQL.update.await(([[UPDATE %s
        SET used_by = ?, used_by_name = ?, used_at = UTC_TIMESTAMP()
        WHERE code = ?]]):format(Vs.SQL.codesTable), { license, playerName, code })

    refreshPlayerVip(src)
    scheduleNextExpiryRefresh(src)

TriggerClientEvent('ox_lib:notify', src, {
    type = 'success',
    description = ('VIP %s aktif sampai %s WIB'):format(Vs.VipJenis[jenis] or jenis, newExpiryWIB)
})

sendDiscord('VIP Redeemed', {
    ['Code']     = code,
    ['Jenis']    = ('%d (%s)'):format(jenis, Vs.VipJenis[jenis]),
    ['Redeemer'] = ('%s (%s)'):format(playerName, steam),
    ['License']  = license or '-',
    ['Expires']  = (newExpiryWIB .. ' WIB'),
})
end, false)

lib.callback.register('tk_vip:server:isAdmin', function(src)
    return isAuthedAdmin(src)
end)

lib.callback.register('tk_vip:server:create_code', function(src, payload)
    local ok, ret = pcall(function()
        if not isAuthedAdmin(src) then
            return { ok=false, error='Tidak berhak.' }
        end

        payload = type(payload) == 'table' and payload or {}
        local jenis    = tonumber(payload.jenis)
        local days     = tonumber(payload.days)
        local targetId = payload.targetId and tonumber(payload.targetId) or nil

        if not jenis or not Vs.VipJenis[jenis] then
            return { ok=false, error='Jenis tidak valid.' }
        end
        if not days or days <= 0 then
            return { ok=false, error='Durasi hari tidak valid.' }
        end
        if Vs.MaxDays and days > Vs.MaxDays then days = Vs.MaxDays end
        local durSec = days * 86400

        local intendedIdentifier, targetName = nil, '-'
        if Vs.LockCodeToIdentifier then
            if not targetId or not GetPlayerName(targetId) then
                return { ok=false, error='Target diperlukan & harus online (Lock aktif).' }
            end
            intendedIdentifier = getLicense(targetId)
            targetName = GetPlayerName(targetId) or ('ID '..targetId)
        elseif targetId and GetPlayerName(targetId) then
            targetName = GetPlayerName(targetId) or ('ID '..targetId)
        end

        local charset = Vs.CodeCharset or 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
        local length  = tonumber(Vs.CodeLength) or 10
        local function genCode()
            local r = {}
            for i=1,length do
                local idx = math.random(#charset)
                r[i] = charset:sub(idx, idx)
            end
            return table.concat(r)
        end

        local code, unique = nil, false
        for _=1,6 do
            code = genCode()
            if not MySQL.single.await(([[SELECT code FROM %s WHERE code = ?]]):format(Vs.SQL.codesTable), { code }) then
                unique = true; break
            end
        end
        if not unique then
            return { ok=false, error='Gagal membuat kode, coba lagi.' }
        end

        local creatorSteam = getSteamHex(src) or 'unknown'
        local creatorName  = GetPlayerName(src) or ('ID '..src)

        MySQL.insert.await(([[INSERT INTO %s
            (code, jenis, duration_seconds, created_by, created_by_name, created_at, intended_identifier)
            VALUES (?, ?, ?, ?, ?, UTC_TIMESTAMP(), ?)]])
            :format(Vs.SQL.codesTable),
            { code, jenis, durSec, creatorSteam, creatorName, intendedIdentifier }
        )

        sendDiscord('VIP Code Created', {
            ['Code']     = code,
            ['Jenis']    = ('%d (%s)'):format(jenis, Vs.VipJenis[jenis]),
            ['Durasi']   = days .. ' hari',
            ['Target']   = targetName,
            ['Intended'] = intendedIdentifier or '-',
            ['Creator']  = ('%s (%s)'):format(creatorName, creatorSteam),
        })

        return { ok=true, code=code, days=days, jenis=jenis, jenisLabel=Vs.VipJenis[jenis], target=targetName }
    end)

    if ok then return ret end
    print(('[tk_vip] create_code error: %s'):format(ret))
    return { ok=false, error='Terjadi kesalahan di server.' }
end)

lib.callback.register('tk_vip:server:list', function(src, payload)
    local ok, ret = pcall(function()
        if not isAuthedAdmin(src) then
            return { ok=false, error='Tidak berhak.' }
        end
        payload = type(payload) == 'table' and payload or {}
        local page = tonumber(payload.page) or 1
        if page < 1 then page = 1 end
        local limit = Vs.PageSize or 20
        local offset = (page - 1) * limit
        local q = tostring(payload.q or ''):gsub('%%','\\%%'):gsub('_','\\_')

        local where = 'v.expires_at > UTC_TIMESTAMP()'
        local params = {}
        if q ~= '' then
            where = where .. ' AND (p.citizenid LIKE ? OR v.identifier LIKE ?)'
            params[#params+1] = '%'..q..'%'
            params[#params+1] = '%'..q..'%'
        end

        local sql = ( [[
            SELECT v.identifier, v.jenis,
                DATE_FORMAT(CONVERT_TZ(v.expires_at,'+00:00','%s'), '%%Y-%%m-%%d %%H:%%i:%%s') AS expiry_wib,
                p.citizenid, p.charinfo
            FROM %s v
            LEFT JOIN %s p ON p.license = v.identifier
            WHERE %s
            ORDER BY v.expires_at DESC
            LIMIT ? OFFSET ?]] ):format(TZ, Vs.SQL.vipTable, Vs.SQL.players, where)

        params[#params+1] = limit
        params[#params+1] = offset

        local rows = MySQL.query.await(sql, params) or {}

        local countSql = ( [[
            SELECT COUNT(*) as total
            FROM %s v
            LEFT JOIN %s p ON p.license = v.identifier
            WHERE %s]] ):format(Vs.SQL.vipTable, Vs.SQL.players, where)
        local countRows = MySQL.query.await(countSql, (q~='' and { '%'..q..'%', '%'..q..'%' } or {}) ) or {}
        local total = countRows[1] and tonumber(countRows[1].total) or 0

        local list = {}
        for _, r in ipairs(rows) do
            local name = nil
            if r.charinfo then
                local okj, cj = pcall(json.decode, r.charinfo)
                if okj and cj and (cj.firstname or cj.lastname) then
                    name = (cj.firstname or '') .. ' ' .. (cj.lastname or '')
                    name = name:gsub('%s+',' '):gsub('^%s*(.-)%s*$','%1')
                end
            end
            list[#list+1] = {
                license   = r.identifier,
                citizenid = r.citizenid or '-',
                steam     = name or '-',
                jenis     = tonumber(r.jenis),
                jenisLabel= Vs.VipJenis[tonumber(r.jenis)] or tostring(r.jenis),
                expiry    = (r.expiry_wib or '') .. ' WIB',
            }
        end

        return { ok=true, items=list, page=page, pageSize=limit, total=total }
    end)

    if ok then return ret end
    print(('[tk_vip] list error: %s'):format(ret))
    return { ok=false, error='Terjadi kesalahan di server.' }
end)

RegisterNetEvent('tk_vip:server:revoke', function(payload)
    local src = source
    if not isAuthedAdmin(src) then return end
    local license = payload and payload.license
    local jenis   = payload and tonumber(payload.jenis)
    if not license or not jenis then return end

    local affected = MySQL.update.await(([[DELETE FROM %s WHERE identifier = ? AND jenis = ?]])
        :format(Vs.SQL.vipTable), { license, jenis })

    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        local lic = getLicense(id)
        if lic == license then
            refreshPlayerVip(id)
            scheduleNextExpiryRefresh(id)
            break
        end
    end

    sendDiscord('VIP Revoked', {
        ['Identifier'] = license,
        ['Jenis']      = ('%d (%s)'):format(jenis, Vs.VipJenis[jenis] or jenis),
        ['By']         = GetPlayerName(src) or ('ID '..src),
    })
end)
