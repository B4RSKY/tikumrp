local Config = require 'gudang.shared.config'

local function unixNow()
    local t = GetCloudTimeAsInt()
    return (type(t) == 'number' and t > 0) and t or 0
end

local function detikToJam(secs)
    if not secs or secs <= 0 then return 'Kadaluarsa' end
    local d = math.floor(secs / 86400); secs = secs % 86400
    local h = math.floor(secs / 3600);  secs = secs % 3600
    local m = math.floor(secs / 60)
    if d > 0 then return ('%d hari %d jam'):format(d, h)
    elseif h > 0 then return ('%d jam %d menit'):format(h, m)
    else return ('%d menit'):format(m) end
end

CreateThread(function()
    Wait(500)
    for key, loc in pairs(Config.Lokasi) do
        exports.ox_target:addBoxZone({
            coords = loc.coords.xyz,
            size = vec3(1.6, 1.6, 2.0),
            rotation = loc.coords.w or 0.0,
            debug = false,
            options = {
                {
                    name = 'sky_gudang' .. key,
                    label = (loc.target and loc.target.label) or 'Gudang',
                    icon  = (loc.target and loc.target.icon) or 'fa-solid fa-warehouse',
                    onSelect = function() 
                        bukaMenuGudang(key) 
                    end
                }
            }
        })
    end
end)

local function menuPerpanjang(locationKey)
    local opts = {}
    for k, v in pairs(Config.RentOptions) do
        opts[#opts+1] = {
        title = v.label,
        icon = 'fa-regular fa-clock',
        onSelect = function() TriggerServerEvent('sky-gudang:server:extend', locationKey, k) end
        }
    end
    table.sort(opts, function(a,b) return a.title < b.title end)
    lib.registerContext({ id = 'sky_gudang_ctx_extend_' .. locationKey, title = 'Perpanjang Sewa', options = opts })
end

local function menuUpgrade(locationKey)
    local opts = {}
    for k, v in pairs(Config.UpgradePlans) do
        opts[#opts+1] = {
        title = v.label,
        icon = 'fa-solid fa-arrow-up-right-dots',
        onSelect = function() TriggerServerEvent('sky-gudang:server:upgrade', locationKey, k) end
        }
    end
    table.sort(opts, function(a,b) return a.title < b.title end)
    lib.registerContext({ id = 'sky_gudang_ctx_upgrade_' .. locationKey, title = 'Upgrade Kapasitas', options = opts })
end

local function menuAutoBill(locationKey, currentKey)
    local opts = {}

    opts[#opts+1] = {
        title = (currentKey and 'Nonaktifkan Auto-Billing' or 'Auto-Billing: OFF'),
        icon = 'fa-regular fa-circle-xmark',
        onSelect = function() TriggerServerEvent('sky-gudang:server:setAutobill', locationKey, false) end
    }

    for k, v in pairs(Config.RentOptions) do
        local isCurr = (currentKey == k)
        opts[#opts+1] = {
        title = (isCurr and ('[Aktif] ' .. v.label) or v.label),
        icon = isCurr and 'fa-solid fa-check' or 'fa-regular fa-clock',
        onSelect = function() TriggerServerEvent('sky-gudang:server:setAutobill', locationKey, k) end
        }
    end
    table.sort(opts, function(a,b) return a.title < b.title end)

    lib.registerContext({
        id = 'sky_gudang_ctx_autobill_' .. locationKey,
        title = 'Pengaturan Auto-Billing',
        options = opts
    })
end

local function confirmCancel(locLabel)
  local ans = lib.alertDialog({
    header = 'Batalkan Sewa?',
    content = ('%s akan DIHAPUS dan SELURUH ISI akan HILANG.\nTidak ada refund.\nLanjutkan?'):format(locLabel),
    centered = true,
    cancel = true,
    labels = { confirm = 'Ya', cancel = 'Batal' }
  })
  return ans == 'confirm'
end

local function menuGudang(locationKey, data)
    local loc = Config.Lokasi[locationKey]; if not loc then return end

    local now = unixNow()
    local expired     = now >= (data.expire_at or 0)
    local graceUntil  = data.grace_until or 0
    local inGrace     = expired and now < graceUntil

    local sisaActive  = (data.expire_at or 0) - now
    local sisaGrace   = (graceUntil - now)

    local capText = ('%d Slot / %d KG'):format(data.slots or 0, math.floor((data.weight or 0)/1000))
    local statusText
    if expired then
        if inGrace then
            statusText = ('Masa Sewa Habis — dihapus dalam %s'):format(detikToJam(sisaGrace))
        else
            statusText = 'Masa Sewa Habis — masa tenggang berakhir'
        end
    else
        statusText = ('Aktif — sisa %s'):format(detikToJam(sisaActive))
    end

    menuPerpanjang(locationKey)
    menuUpgrade(locationKey)
    menuAutoBill(locationKey, data.autobill_key)

    local options = {}

    options[#options+1] = {
        title = 'Durasi Sewa: '..statusText,
        icon = 'fa-regular fa-clock',
    }
    if expired then
        options[#options+1] = {
            title = 'Buka Gudang (Terkunci)',
            description = 'Perpanjang atau aktifkan auto-billing.',
            icon = 'fa-solid fa-lock',
            onSelect = function()
                lib.notify({ title = 'Gudang Kadaluarsa', description = 'Perpanjang sewa agar bisa dibuka kembali.', type = 'error' })
            end
        }
    else
        options[#options+1] = {
            title = 'Buka Gudang',
            description = 'Kapasitas: ' .. capText,
            icon = 'fa-solid fa-box-open',
            onSelect = function() exports.ox_inventory:openInventory('stash', data.stash_id) end
        }
    end

    options[#options+1] = {
        title = 'Perpanjang Sewa',
        description = expired and 'Aktifkan kembali masa sewa' or 'Tambahkan durasi',
        icon = 'fa-regular fa-clock',
        menu = 'sky_gudang_ctx_extend_' .. locationKey
    }

    options[#options+1] = expired and {
        title = 'Upgrade Kapasitas (Perlu aktif)',
        description = 'Perpanjang dulu untuk meng-upgrade',
        icon = 'fa-solid fa-arrow-up-right-dots',
        onSelect = function()
            lib.notify({ title = 'Tidak bisa upgrade', description = 'Sewa kadaluarsa. Perpanjang terlebih dahulu.', type = 'error' })
        end
    } or {
        title = 'Upgrade Kapasitas',
        description = 'Tambah kapasitas weight/slots (barang aman)',
        icon = 'fa-solid fa-arrow-up-right-dots',
        menu = 'sky_gudang_ctx_upgrade_' .. locationKey
    }

    local abLabel = data.autobill_key and ('ON (' .. (Config.RentOptions[data.autobill_key] and Config.RentOptions[data.autobill_key].label or '?') .. ')') or 'OFF'
    options[#options+1] = {
        title = 'Auto-Billing: ' .. abLabel,
        description = 'Otomatis perpanjang saat expired',
        icon = 'fa-solid fa-rotate',
        menu = 'sky_gudang_ctx_autobill_' .. locationKey
    }

    options[#options+1] = {
        title = 'Batal Sewa',
        description = expired and 'Kontrak kadaluarsa (tenggang). Batal sekarang akan menghapus gudang & isi.' or 'Kontrak aktif. Batal sekarang akan menghapus gudang & isi.',
        icon = 'fa-solid fa-trash-can',
        onSelect = function()
            local locLabel = loc.label or locationKey
            if confirmCancel(locLabel) then
                TriggerServerEvent('sky-gudang:server:cancel', locationKey)
            end
        end
    }

    lib.registerContext({
        id = 'sky_gudang_ctx_' .. locationKey,
        title = ('%s'):format(loc.label),
        options = options
    })
    lib.showContext('sky_gudang_ctx_' .. locationKey)
end

function bukaMenuGudang(locationKey)
    local loc = Config.Lokasi[locationKey]; if not loc then return end
    local data = lib.callback.await('sky-gudang:server:getInfo', false, locationKey)

    if not data then
        local opts = {}
        for k, v in pairs(Config.RentOptions) do
        opts[#opts+1] = { value = k, label = v.label }
        end
        table.sort(opts, function(a,b) return a.value < b.value end)

        local input = lib.inputDialog(('Sewa Gudang - %s'):format(loc.label), {
        { type = 'select', label = 'Durasi Sewa', options = opts, required = true },
        { type = 'checkbox', label = 'Saya paham: ada masa tenggang 3 hari setelah kadaluarsa, lewat itu gudang & isi akan dihapus.', required = true }
        })
        if not input or not input[1] then return end
        TriggerServerEvent('sky-gudang:server:rent', locationKey, input[1])
        return
    end
    menuGudang(locationKey, data)
end