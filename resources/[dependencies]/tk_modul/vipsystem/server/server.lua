local Config = require 'vipsystem.shared.config'
local Vs = Config.VipSystem
local QBCore = exports['qb-core']:GetCoreObject()

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
    refreshPlayerVip(src)

    local license = getLicense(src)
    if license and Vs.ExpiryWarnDays and Vs.ExpiryWarnDays > 0 then
        local rows = MySQL.query.await(([[SELECT jenis, TIMESTAMPDIFF(DAY, UTC_TIMESTAMP(), expires_at) AS days_left
            FROM %s WHERE identifier = ? AND expires_at > UTC_TIMESTAMP()]])
            :format(Vs.SQL.vipTable), { license })
        for _, r in ipairs(rows or {}) do
            if r.days_left and tonumber(r.days_left) <= Vs.ExpiryWarnDays then
                TriggerClientEvent('ox_lib:notify', src, { type = 'inform',
                    description = ('VIP %s sisa %d hari'):format(Vs.VipJenis[tonumber(r.jenis)] or r.jenis, r.days_left) })
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
    local rows = MySQL.query.await(([[SELECT jenis, DATE_FORMAT(expires_at, '%%Y-%%m-%%d %%H:%%i:%%s') AS expiry
        FROM %s WHERE identifier = ? AND expires_at > UTC_TIMESTAMP() ORDER BY expires_at DESC]])
        :format(Vs.SQL.vipTable), { license })

    if not rows or #rows == 0 then
        TriggerClientEvent('ox_lib:notify', src, { type='inform', description='Kamu tidak memiliki VIP aktif.' })
        return
    end

    for _, r in ipairs(rows) do
        TriggerClientEvent('ox_lib:notify', src, {
            type='success',
            description = ('%s (jenis %d) aktif s/d %s UTC')
                :format(Vs.VipJenis[tonumber(r.jenis)] or r.jenis, r.jenis, r.expiry)
        })
    end
end, false)

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

    local newExpiry = MySQL.scalar.await(
        ([[SELECT DATE_FORMAT(expires_at, '%%Y-%%m-%%d %%H:%%i:%%s') FROM %s WHERE identifier = ? AND jenis = ?]])
            :format(Vs.SQL.vipTable), { license, jenis }
    )

    MySQL.update.await(([[UPDATE %s
        SET used_by = ?, used_by_name = ?, used_at = UTC_TIMESTAMP()
        WHERE code = ?]]):format(Vs.SQL.codesTable), { license, playerName, code })

    refreshPlayerVip(src)

    TriggerClientEvent('ox_lib:notify', src, { type = 'success',
        description = ('VIP %s aktif sampai %s'):format(Vs.VipJenis[jenis] or jenis, newExpiry) })

    sendDiscord('VIP Redeemed', {
        ['Code']     = code,
        ['Jenis']    = ('%d (%s)'):format(jenis, Vs.VipJenis[jenis]),
        ['Redeemer'] = ('%s (%s)'):format(playerName, steam),
        ['License']  = license or '-',
        ['Expires']  = newExpiry,
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
                   DATE_FORMAT(v.expires_at, '%%Y-%%m-%%d %%H:%%i:%%s') AS expiry,
                   p.citizenid, p.charinfo
            FROM %s v
            LEFT JOIN %s p ON p.license = v.identifier
            WHERE %s
            ORDER BY v.expires_at DESC
            LIMIT ? OFFSET ?]] ):format(Vs.SQL.vipTable, Vs.SQL.players, where)

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
                expiry    = (r.expiry or '') .. ' UTC',
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
            break
        end
    end

    sendDiscord('VIP Revoked', {
        ['Identifier'] = license,
        ['Jenis']      = ('%d (%s)'):format(jenis, Vs.VipJenis[jenis] or jenis),
        ['By']         = GetPlayerName(src) or ('ID '..src),
    })
end)
