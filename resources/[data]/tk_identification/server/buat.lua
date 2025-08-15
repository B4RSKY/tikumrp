local QBCore = exports['qb-core']:GetCoreObject()
local _cooldown = {}

-- ================== UTIL ==================
local function isJobAllowed(src)
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return false end
    local job = xPlayer.PlayerData.job
    if not job then return false end
    local needed = Config.Server and Config.Server.AllowedJobs and Config.Server.AllowedJobs[job.name]
    return needed and (job.grade.level >= needed)
end

local function withinDistance(src, targetId)
    local srcPed = GetPlayerPed(src)
    local tgtPed = GetPlayerPed(targetId)
    if srcPed == 0 or tgtPed == 0 then return false end
    local sc = GetEntityCoords(srcPed)
    local tc = GetEntityCoords(tgtPed)
    return #(sc - tc) <= (Config.MaxDistanceToTarget or 4.5)
end

local function discordLog(title, message)
    if not (Config.Server and Config.Server.Webhook) or Config.Server.Webhook == '' then return end
    PerformHttpRequest(Config.Server.Webhook, function() end, 'POST', json.encode({
        username = 'License Manager',
        embeds = {{ title = title, description = message, color = 16729344 }}
    }), { ['Content-Type'] = 'application/json' })
end

-- ================== UTIL: Ambil label tipe ==================
local function typeLabel(code)
    local t = Config.LicenseTypes[code]
    return t and (t.title or code) or code
end

-- ================== AUDIT LOG ==================
local function auditLog(action, src, holderCid, ltype, licenseId, details, sourceTag)
    local actorName, actorCid, actorJob, actorGrade = nil, nil, nil, nil
    if src then
        local p = QBCore.Functions.GetPlayer(src)
        if p then
            local ci = p.PlayerData.charinfo or {}
            actorName  = (ci.firstname or '') .. ' ' .. (ci.lastname or '')
            actorCid   = p.PlayerData.citizenid
            actorJob   = p.PlayerData.job and p.PlayerData.job.name or nil
            actorGrade = p.PlayerData.job and p.PlayerData.job.grade.level or nil
        end
    end

    MySQL.insert.await([[
        INSERT INTO sky_license_log
        (license_id, ts, action, actor_citizenid, actor_name, actor_job, actor_grade,
         holder_citizenid, holder_name, license_type, details, source)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        licenseId or nil,
        os.time(),
        action,
        actorCid,
        actorName,
        actorJob,
        actorGrade,
        holderCid,
        nil,
        ltype,
        details and json.encode(details) or nil,
        sourceTag or 'system'
    })
end

local function getNameFromCharinfo(charinfo)
    if not charinfo then return 'Unknown' end
    local ok, data = pcall(json.decode, charinfo)
    if not ok or type(data) ~= 'table' then return 'Unknown' end
    local fn = data.firstname or ''
    local ln = data.lastname or ''
    local name = (fn ~= '' or ln ~= '') and (fn .. ' ' .. ln) or 'Unknown'
    return name
end

-- ================== ISSUE (sudah ada) ==================
local function issueKtpTo(targetId, mugshotURL, expire)
    local tgt = QBCore.Functions.GetPlayer(targetId)
    if not tgt then return false, 'Player target tidak online.' end

    local now = os.time()
    if not expire or expire <= now then
        return false, 'Tanggal berlaku tidak valid.'
    end

    if Config.Server and Config.Server.RemoveOldOnReissue then
        local count = exports.ox_inventory:Search(targetId, 'count', Config.ItemName)
        if count and count > 0 then
            exports.ox_inventory:RemoveItem(targetId, Config.ItemName, count)
        end
    end

    local pd = tgt.PlayerData.charinfo
    local meta = {
        type = (pd.firstname .. ' ' .. pd.lastname),
        citizenid = tgt.PlayerData.citizenid,
        firstName = pd.firstname,
        lastName = pd.lastname,
        dateofbirth = pd.birthdate,
        sex = (pd.gender == 0 and 'Male' or 'Female'),
        nationality = pd.nationality,
        mugshoturl = mugshotURL or '',
        cardtype = Config.ItemName,
        issuedon = os.date('%d/%m/%Y', now),
        expireson = os.date('%d/%m/%Y', expire),
        expiryTimestamp = expire,
        description = ('Name: %s %s\nSex: %s\nDOB: %s\nNationality: %s\nBerlaku: %s'):format(
            pd.firstname, pd.lastname,
            (pd.gender == 0 and 'Male' or 'Female'),
            pd.birthdate, pd.nationality,
            os.date('%d/%m/%Y', expire)
        )
    }

    local ok = exports.ox_inventory:AddItem(targetId, Config.ItemName, 1, meta)
    if not ok then return false, 'Gagal menambahkan item (inventory penuh?).' end

    -- DB logging -> sky_license
    if Config.Server and Config.Server.UseLicenseTable then
        local issuer = QBCore.Functions.GetPlayer(source)
        local issuerName = 'CONSOLE' ; local issuerCid = 'CONSOLE'
        if issuer then
            local ci = issuer.PlayerData.charinfo or {}
            issuerName = (ci.firstname or '') .. ' ' .. (ci.lastname or '')
            issuerCid  = issuer.PlayerData.citizenid or 'UNKNOWN'
        end

        MySQL.insert.await(
            'INSERT INTO sky_license (license_type, holder_citizenid, issuer_name, issuer_citizenid, issued_at, expires_at) VALUES (?, ?, ?, ?, ?, ?)',
            { Config.ItemName, tgt.PlayerData.citizenid, issuerName, issuerCid, now, expire }
        )
    end

    -- Jadwal hapus saat expired (one-shot)
    local delay = math.max(60, (expire - os.time())) * 1000
    SetTimeout(delay, function()
        local p = QBCore.Functions.GetPlayer(targetId)
        if not p then return end
        local items = exports.ox_inventory:Search(p.PlayerData.source, 'slots', Config.ItemName)
        if items then
            for slot, item in pairs(items) do
                if item.metadata and item.metadata.expiryTimestamp and os.time() >= item.metadata.expiryTimestamp then
                    exports.ox_inventory:RemoveItem(p.PlayerData.source, Config.ItemName, item.count, item.metadata, slot)
                    TriggerClientEvent('QBCore:Notify', p.PlayerData.source, 'KTP Anda kedaluwarsa dan dihapus.', 'error')
                end
            end
        end
    end)

    return true
end

-- ================== CALLBACK: LIST LICENSE (pagination + search) ==================
lib.callback.register('sky-license:server:getLicenses', function(src, page, pageSize, arg4)
    if not isJobAllowed(src) then return nil end

    local x = QBCore.Functions.GetPlayer(src)
    if not x or not x.PlayerData or not x.PlayerData.job then return nil end

    local search, statusFilter
    if type(arg4) == 'table' then
        search = arg4.search
        statusFilter = arg4.status
    else
        search = arg4
        statusFilter = nil
    end

    local jobName = x.PlayerData.job.name
    local perm = Config.Server.Permissions and Config.Server.Permissions[jobName] or nil
    local allowedTypes = perm and perm.jenis_license or {}
    if not allowedTypes or #allowedTypes == 0 then
        return { total = 0, items = {} }
    end

    page = tonumber(page) or 1
    pageSize = math.min(tonumber(pageSize) or 10, 25)
    local offset = (page - 1) * pageSize

    local whereParts, params = {}, {}

    -- Selalu sembunyikan revoked
    whereParts[#whereParts+1] = 'l.status <> "revoked"'

    -- Filter status opsional
    if statusFilter == 'active' then
        whereParts[#whereParts+1] = '(l.status = "active" AND l.expires_at > UNIX_TIMESTAMP())'
    elseif statusFilter == 'expired' then
        whereParts[#whereParts+1] = '((l.status = "expired") OR (l.expires_at <= UNIX_TIMESTAMP()))'
    else
        -- 'all' atau nil → tidak menambah kondisi ekstra
    end

    -- Batasi hanya tipe yang boleh dikelola job ini
    local qm = {}
    for _ = 1, #allowedTypes do qm[#qm+1] = '?' end
    whereParts[#whereParts+1] = ('l.license_type IN (%s)'):format(table.concat(qm, ','))
    for _, t in ipairs(allowedTypes) do params[#params+1] = t end

    -- Search
    if search and search ~= '' then
        whereParts[#whereParts+1] = '(l.holder_citizenid LIKE ? OR l.issuer_citizenid LIKE ? OR p.charinfo LIKE ?)'
        local s = ('%%%s%%'):format(search)
        params[#params+1] = s
        params[#params+1] = s
        params[#params+1] = s
    end

    local whereSql = (#whereParts > 0) and ('WHERE ' .. table.concat(whereParts, ' AND ')) or ''

    -- COUNT
    local total = MySQL.scalar.await(([[ 
        SELECT COUNT(*)
        FROM sky_license l
        LEFT JOIN players p ON p.citizenid = l.holder_citizenid
        %s
    ]]):format(whereSql), params) or 0

    -- ROWS
    local rowParams = {}
    for i=1,#params do rowParams[i] = params[i] end
    rowParams[#rowParams+1] = pageSize
    rowParams[#rowParams+1] = offset

    local rows = MySQL.query.await(([[ 
        SELECT l.id, l.license_type, l.holder_citizenid, l.issuer_name, l.issuer_citizenid,
               l.issued_at, l.expires_at, l.status, p.charinfo
        FROM sky_license l
        LEFT JOIN players p ON p.citizenid = l.holder_citizenid
        %s
        ORDER BY l.created_at DESC, l.id DESC
        LIMIT ? OFFSET ?
    ]]):format(whereSql), rowParams)

    local items = {}
    for _, r in ipairs(rows or {}) do
        local holderName = getNameFromCharinfo(r.charinfo)
        items[#items+1] = {
            id = r.id,
            license_type = r.license_type,
            holder_citizenid = r.holder_citizenid,
            holder_name = holderName,
            issuer_name = r.issuer_name,
            issuer_citizenid = r.issuer_citizenid,
            issued_at = r.issued_at,
            expires_at = r.expires_at,
            issued_at_h = os.date('%d/%m/%Y', r.issued_at),
            expires_at_h = os.date('%d/%m/%Y', r.expires_at),
            status = r.status
        }
    end

    return { total = total, items = items }
end)

-- ================== CALLBACK: tipe yang boleh diterbitkan job ini ==================
lib.callback.register('sky-license:server:getIssuableTypes', function(src)
    local x = QBCore.Functions.GetPlayer(src)
    if not x or not x.PlayerData.job then return {} end
    local job = x.PlayerData.job.name
    local perm = Config.Server.Permissions[job]
    if not perm or (x.PlayerData.job.grade.level < (perm.min_grade or 0)) then return {} end

    local out = {}
    for _, code in ipairs(perm.jenis_license or {}) do
        local t = Config.LicenseTypes[code]
        if t then
            out[#out+1] = { code = code, title = t.title }
        end
    end
    return out
end)

-- ==== [SERVER] Izin melihat audit ====
local function canViewAudit(src)
    local x = QBCore.Functions.GetPlayer(src)
    if not x or not x.PlayerData.job then return false end
    local job = x.PlayerData.job.name
    local perm = Config.Server.Permissions and Config.Server.Permissions[job]
    if not perm then return false end
    return (x.PlayerData.job.grade.level >= (perm.min_grade or 0))
end

-- ==== Formatter nama (reuse) ====
local function _nameFromCharinfoStr(ciStr)
    if not ciStr then return nil end
    local ok, ci = pcall(json.decode, ciStr)
    if not ok or type(ci) ~= 'table' then return nil end
    local fn = ci.firstname or ''
    local ln = ci.lastname or ''
    local nm = (fn ~= '' or ln ~= '') and (fn .. ' ' .. ln) or nil
    return nm
end

-- ==== Ringkas details JSON → string ====
local function summarizeDetails(action, detailsJson, expires_at)
    local txt = nil
    local d
    if detailsJson then
        local ok, parsed = pcall(json.decode, detailsJson)
        if ok and type(parsed) == 'table' then d = parsed end
    end
    if action == 'issue' then
        txt = ('expires: %s'):format(os.date('%d/%m/%Y', expires_at or (d and d.expires_new or os.time())))
    elseif action == 'extend' then
        local ne = d and d.expires_new
        if ne then txt = ('new expiry: %s'):format(os.date('%d/%m/%Y', ne)) end
    elseif action == 'revoke' then
        txt = 'revoked by officer'
    elseif action == 'auto_expire' then
        txt = 'auto expired'
    elseif action == 'auto_suspend' then
        txt = 'auto suspended (job/dept mismatch)'
    elseif action == 'auto_reactivate' then
        txt = 'auto reactivated'
    elseif action == 'sync_update' then
        if d and d.remove_item then txt = 'inventory item removed'
        elseif d and d.expiry_sync then txt = ('expiry synced: %s'):format(os.date('%d/%m/%Y', d.expiry_sync))
        end
    elseif action == 'reissue_item' then
        txt = 'item reissued'
    end
    if not txt and detailsJson then
        -- fallback tampilkan JSON mentah (dipotong)
        txt = detailsJson
        if #txt > 200 then txt = txt:sub(1, 200) .. '…' end
    end
    return txt
end

-- ==== Callback: Audit Global (dengan filter) ====
lib.callback.register('sky-license:server:getAudit', function(src, page, pageSize, filters)
    if not canViewAudit(src) then return nil end
    page = tonumber(page) or 1
    pageSize = math.min(tonumber(pageSize) or 10, 25)
    local offset = (page - 1) * pageSize

    -- Build WHERE dinamis
    local where = {}
    local params = {}

    if filters then
        if filters.license_type and filters.license_type ~= '' then
            where[#where+1] = 'l.license_type = @t'
            params['t'] = filters.license_type
        end
        if filters.action and filters.action ~= '' then
            where[#where+1] = 'l.action = @a'
            params['a'] = filters.action
        end
        if filters.actor and filters.actor ~= '' then
            where[#where+1] = '(l.actor_citizenid LIKE @ac OR l.actor_name LIKE @ac OR l.actor_job LIKE @ac)'
            params['ac'] = '%' .. filters.actor .. '%'
        end
        if filters.holder and filters.holder ~= '' then
            where[#where+1] = '(l.holder_citizenid LIKE @hc OR p.charinfo LIKE @hc)'
            params['hc'] = '%' .. filters.holder .. '%'
        end
        if filters.from then
            where[#where+1] = 'l.ts >= @from'
            params['from'] = math.floor(filters.from / 1000)
        end
        if filters.to then
            where[#where+1] = 'l.ts <= @to'
            params['to'] = math.floor(filters.to / 1000) + 86399
        end
    end

    local whereSql = (#where > 0) and ('WHERE ' .. table.concat(where, ' AND ')) or ''

    -- Total
    local total = MySQL.scalar.await(([[
        SELECT COUNT(*) FROM sky_license_log l
        LEFT JOIN sky_license c ON c.id = l.license_id
        LEFT JOIN players p ON p.citizenid = l.holder_citizenid
        %s
    ]]):format(whereSql), params) or 0

    -- Rows
    params['limit'] = pageSize
    params['offset'] = offset
    local rows = MySQL.query.await(([[
        SELECT l.id, l.license_id, l.ts, l.action, l.actor_citizenid, l.actor_name, l.actor_job, l.actor_grade,
               l.holder_citizenid, l.license_type, l.details,
               c.expires_at,
               p.charinfo
        FROM sky_license_log l
        LEFT JOIN sky_license c ON c.id = l.license_id
        LEFT JOIN players p ON p.citizenid = l.holder_citizenid
        %s
        ORDER BY l.ts DESC, l.id DESC
        LIMIT @limit OFFSET @offset
    ]]):format(whereSql), params)

    local items = {}
    for _, r in ipairs(rows or {}) do
        local holderName = _nameFromCharinfoStr(r.charinfo)
        local actorDisp = r.actor_name and r.actor_citizenid and (('%s (%s)'):format(r.actor_name, r.actor_citizenid)) or (r.actor_name or r.actor_citizenid)
        local actorJG = (r.actor_job and r.actor_grade) and (('%s-%s'):format(r.actor_job, r.actor_grade)) or (r.actor_job or nil)
        items[#items+1] = {
            id = r.id,
            license_id = r.license_id,
            ts = r.ts,
            ts_h = os.date('%d/%m/%Y %H:%M', r.ts),
            action = r.action,
            actor_disp = actorDisp,
            actor_jobgrade = actorJG,
            holder_disp = holderName and (('%s (%s)'):format(holderName, r.holder_citizenid)) or r.holder_citizenid,
            license_type = r.license_type or 'unknown',
            details_h = summarizeDetails(r.action, r.details, r.expires_at),
        }
    end

    return { total = total, items = items, page = page, pageSize = pageSize }
end)

-- ==== Callback: Audit Per License ====
lib.callback.register('sky-license:server:getAuditByLicense', function(src, licenseId, page, pageSize)
    if not canViewAudit(src) then return nil end
    page = tonumber(page) or 1
    pageSize = math.min(tonumber(pageSize) or 10, 25)
    local offset = (page - 1) * pageSize

    local total = MySQL.scalar.await('SELECT COUNT(*) FROM sky_license_log WHERE license_id = @id', { ['id'] = licenseId }) or 0
    local rows = MySQL.query.await([[
        SELECT l.id, l.license_id, l.ts, l.action, l.actor_citizenid, l.actor_name, l.actor_job, l.actor_grade,
               l.holder_citizenid, l.license_type, l.details, c.expires_at
        FROM sky_license_log l
        LEFT JOIN sky_license c ON c.id = l.license_id
        WHERE l.license_id = @id
        ORDER BY l.ts DESC, l.id DESC
        LIMIT @limit OFFSET @offset
    ]], { ['id'] = licenseId, ['limit'] = pageSize, ['offset'] = offset })

    local items = {}
    for _, r in ipairs(rows or {}) do
        local actorDisp = r.actor_name and r.actor_citizenid and (('%s (%s)'):format(r.actor_name, r.actor_citizenid)) or (r.actor_name or r.actor_citizenid)
        local actorJG = (r.actor_job and r.actor_grade) and (('%s-%s'):format(r.actor_job, r.actor_grade)) or (r.actor_job or nil)
        items[#items+1] = {
            id = r.id,
            license_id = r.license_id,
            ts = r.ts,
            ts_h = os.date('%d/%m/%Y %H:%M', r.ts),
            action = r.action,
            actor_disp = actorDisp,
            actor_jobgrade = actorJG,
            holder_disp = r.holder_citizenid,
            license_type = r.license_type or 'unknown',
            details_h = summarizeDetails(r.action, r.details, r.expires_at),
        }
    end

    return { total = total, items = items, page = page, pageSize = pageSize }
end)


-- ================== EXTEND LICENSE (REPLACE WHOLE HANDLER) ==================
RegisterNetEvent('sky-license:server:extendLicense', function(licenseId, newExpire)
    local src = source
    if not isJobAllowed(src) then
        return TriggerClientEvent('QBCore:Notify', src, 'Tidak diizinkan.', 'error')
    end

    -- rate limit sederhana
    local last = _cooldown[src] or 0
    if (os.time() - last) < (Config.RateLimitSeconds or 5) then
        return TriggerClientEvent('QBCore:Notify', src, 'Terlalu cepat, coba lagi.', 'error')
    end
    _cooldown[src] = os.time()

    newExpire = tonumber(newExpire)
    if not newExpire or newExpire <= os.time() then
        return TriggerClientEvent('QBCore:Notify', src, 'Tanggal baru tidak valid.', 'error')
    end
    if Config.MaxValidityDays and newExpire - os.time() > Config.MaxValidityDays * 86400 then
        return TriggerClientEvent('QBCore:Notify', src, 'Melebihi batas maksimal.', 'error')
    end

    -- Ambil data lisensi (butuh license_type untuk map item)
    local row = MySQL.single.await('SELECT * FROM sky_license WHERE id = ? LIMIT 1', { licenseId })
    if not row then
        return TriggerClientEvent('QBCore:Notify', src, 'License tidak ditemukan.', 'error')
    end

    -- Update DB expiry
    MySQL.update.await('UPDATE sky_license SET expires_at = ?, status = ? WHERE id = ?', {
        newExpire, 'active', licenseId
    })

    -- Sinkron item jika holder online
    local itemName = Config.LicenseTypes[row.license_type] and Config.LicenseTypes[row.license_type].item
    local holder = QBCore.Functions.GetPlayerByCitizenId(row.holder_citizenid)
    if holder and itemName then
        local hsrc = holder.PlayerData.source
        local items = exports.ox_inventory:Search(hsrc, 'slots', itemName)
        if items then
            for slot, it in pairs(items) do
                if it.metadata then
                    local meta = it.metadata
                    meta.expireson = os.date('%d/%m/%Y', newExpire)
                    meta.expiryTimestamp = newExpire
                    meta.description = meta.description and meta.description:gsub('Berlaku: .+', 'Berlaku: ' .. meta.expireson) or meta.description

                    exports.ox_inventory:RemoveItem(hsrc, itemName, 1, it.metadata, slot)
                    exports.ox_inventory:AddItem(hsrc, itemName, 1, meta)
                    break
                end
            end
        end
        TriggerClientEvent('QBCore:Notify', hsrc, ('%s Anda diperpanjang hingga %s.'):format(
            (Config.LicenseTypes[row.license_type] and Config.LicenseTypes[row.license_type].title) or row.license_type,
            os.date('%d/%m/%Y', newExpire)
        ), 'success')
    end

    -- Audit + notifikasi petugas
    auditLog('extend', src, row.holder_citizenid, row.license_type, row.id, { expires_new = newExpire }, 'officer_panel')
    TriggerClientEvent('QBCore:Notify', src, 'Berhasil memperpanjang license.', 'success')
end)

-- ================== REVOKE LICENSE (REPLACE WHOLE HANDLER) ==================
RegisterNetEvent('sky-license:server:revokeLicense', function(licenseId)
    local src = source
    if not isJobAllowed(src) then
        return TriggerClientEvent('QBCore:Notify', src, 'Tidak diizinkan.', 'error')
    end

    -- rate limit sederhana
    local last = _cooldown[src] or 0
    if (os.time() - last) < (Config.RateLimitSeconds or 5) then
        return TriggerClientEvent('QBCore:Notify', src, 'Terlalu cepat, coba lagi.', 'error')
    end
    _cooldown[src] = os.time()

    -- Ambil data lisensi
    local row = MySQL.single.await('SELECT * FROM sky_license WHERE id = ? LIMIT 1', { licenseId })
    if not row then
        return TriggerClientEvent('QBCore:Notify', src, 'License tidak ditemukan.', 'error')
    end

    -- Hapus item kalau holder online
    local itemName = Config.LicenseTypes[row.license_type] and Config.LicenseTypes[row.license_type].item
    local holder = QBCore.Functions.GetPlayerByCitizenId(row.holder_citizenid)
    if holder and itemName then
        local hsrc = holder.PlayerData.source
        local items = exports.ox_inventory:Search(hsrc, 'slots', itemName)
        if items then
            for slot, it in pairs(items) do
                exports.ox_inventory:RemoveItem(hsrc, itemName, it.count or 1, it.metadata, slot)
            end
        end
        TriggerClientEvent('QBCore:Notify', hsrc, ('%s Anda telah dicabut.'):format(
            (Config.LicenseTypes[row.license_type] and Config.LicenseTypes[row.license_type].title) or row.license_type
        ), 'error')
    end

    -- Audit dulu (biar ada jejak license_id), lalu hapus row
    auditLog('revoke', src, row.holder_citizenid, row.license_type, row.id, nil, 'officer_panel')
    MySQL.update.await('UPDATE sky_license SET status = ? WHERE id = ?', { 'revoked', licenseId })

    -- Notifikasi petugas
    TriggerClientEvent('QBCore:Notify', src, 'License berhasil di-revoke.', 'success')
end)

----------------------------------------------------------------
-- EVENT SELF-SERVICE (tetap)
----------------------------------------------------------------
RegisterNetEvent('sky-license:server:selfCreate', function(mugshotURL)
    local src = source

    local last = _cooldown[src] or 0
    if (os.time() - last) < (Config.RateLimitSeconds or 5) then
        return TriggerClientEvent('QBCore:Notify', src, 'Terlalu cepat, coba lagi sebentar.', 'error')
    end
    _cooldown[src] = os.time()

    if mugshotURL and type(mugshotURL) == 'string' and #mugshotURL > 120000 then
        return TriggerClientEvent('QBCore:Notify', src, 'Foto terlalu besar.', 'error')
    end

    local now = os.time()
    local oneMonth = 30 * 24 * 60 * 60
    local expire = now + oneMonth

    local ok, err = issueKtpTo(src, mugshotURL or '', expire)
    if not ok then
        return TriggerClientEvent('QBCore:Notify', src, err or 'Gagal membuat KTP.', 'error')
    end

    TriggerClientEvent('QBCore:Notify', src, ('KTP berhasil dibuat. Berlaku hingga %s.'):format(os.date('%d/%m/%Y', expire)), 'success')
    discordLog('KTP Diterbitkan (Self-Service)', ('Player: %s | Exp: %s'):format(
        src, os.date('%d/%m/%Y', expire)
    ))
end)

-- ================== ISSUE GENERIC (requestData + create) ==================
RegisterNetEvent('sky-license:server:requestData', function(licenseType, targetId, photo, expireMs)
    local src = source
    local x = QBCore.Functions.GetPlayer(src)
    if not x then return end

    local perm = x.PlayerData.job and Config.Server.Permissions[x.PlayerData.job.name]
    if not perm or x.PlayerData.job.grade.level < (perm.min_grade or 0) then
        return TriggerClientEvent('QBCore:Notify', src, 'Tidak diizinkan.', 'error')
    end
    local allowed = false
    for _, code in ipairs(perm.jenis_license or {}) do if code == licenseType then allowed = true break end end
    if not allowed then
        return TriggerClientEvent('QBCore:Notify', src, 'Job tidak boleh menerbitkan tipe ini.', 'error')
    end

    local tgt = QBCore.Functions.GetPlayer(tonumber(targetId) or -1)
    if not tgt then return TriggerClientEvent('QBCore:Notify', src, 'Player target tidak online.', 'error') end
    if not withinDistance(src, tgt.PlayerData.source) then
        return TriggerClientEvent('QBCore:Notify', src, 'Terlalu jauh dari target.', 'error')
    end

    local tdef = Config.LicenseTypes[licenseType]
    if not tdef then return TriggerClientEvent('QBCore:Notify', src, 'Tipe license tidak dikenal.', 'error') end

    -- expiry check
    local expire = math.floor((tonumber(expireMs) or 0) / 1000)
    local now = os.time()
    if expire <= now then
        return TriggerClientEvent('QBCore:Notify', src, 'Tanggal berlaku tidak valid.', 'error')
    end
    if Config.MaxValidityDays and (expire - now) > Config.MaxValidityDays * 86400 then
        return TriggerClientEvent('QBCore:Notify', src, 'Melebihi batas maksimal.', 'error')
    end

    if tdef.require_photo then
        if photo and type(photo) == 'string' then
            if #photo > 120000 then
                return TriggerClientEvent('QBCore:Notify', src, 'Foto terlalu besar.', 'error')
            end
        else
            return TriggerClientEvent('QBCore:Notify', src, 'Foto diperlukan.', 'error')
        end
    else
        photo = ''
    end

    local pd = tgt.PlayerData.charinfo
    local confirmDlg = {
        { type = 'input', label = 'Jenis License', default = typeLabel(licenseType), disabled = true },
        { type = 'input', label = 'Nama',          default = (pd.firstname .. ' ' .. pd.lastname), disabled = true },
        { type = 'input', label = 'Citizen ID',    default = tgt.PlayerData.citizenid, disabled = true },
        { type = 'input', label = 'Tanggal Lahir', default = pd.birthdate, disabled = true },
        { type = 'input', label = 'Berlaku Sampai',default = os.date('%d/%m/%Y', expire), disabled = true },
        { type = 'checkbox', label = 'Konfirmasi penerbitan', required = true }
    }
    -- kirim ke client event BARU, bawa licenseType terpisah
    TriggerClientEvent('tk:lic:cl:showConfirm', src, confirmDlg, licenseType, tgt.PlayerData.source, photo or '', expire)
end)

RegisterNetEvent('sky-license:server:Buatin', function(licenseType, targetId, photo, expireTs)
    local src = source
    local x = QBCore.Functions.GetPlayer(src)
    if not x then return end

    local perm = x.PlayerData.job and Config.Server.Permissions[x.PlayerData.job.name]
    if not perm or x.PlayerData.job.grade.level < (perm.min_grade or 0) then
        return TriggerClientEvent('QBCore:Notify', src, 'Tidak diizinkan.', 'error')
    end
    local allowed = false
    for _, code in ipairs(perm.jenis_license or {}) do if code == licenseType then allowed = true break end end
    if not allowed then
        return TriggerClientEvent('QBCore:Notify', src, 'Job tidak boleh menerbitkan tipe ini.', 'error')
    end

    local tgt = QBCore.Functions.GetPlayer(tonumber(targetId) or -1)
    if not tgt then return TriggerClientEvent('QBCore:Notify', src, 'Target tidak online.', 'error') end

    -- Reuse issue function tapi generik per-type
    local tdef = Config.LicenseTypes[licenseType]
    if not tdef then return TriggerClientEvent('QBCore:Notify', src, 'Tipe license tidak dikenal.', 'error') end

    -- Hapus lisensi/item lama (opsional)
    if Config.Server and Config.Server.RemoveOldOnReissue then
        local item = tdef.item
        local count = exports.ox_inventory:Search(tgt.PlayerData.source, 'count', item)
        if count and count > 0 then
            exports.ox_inventory:RemoveItem(tgt.PlayerData.source, item, count)
        end
    end

    local now = os.time()
    local expire = tonumber(expireTs)
    if not expire or expire <= now then
        return TriggerClientEvent('QBCore:Notify', src, 'Tanggal berlaku tidak valid.', 'error')
    end

    local pd = tgt.PlayerData.charinfo
    local meta = {
        type = (pd.firstname .. ' ' .. pd.lastname),
        citizenid = tgt.PlayerData.citizenid,
        firstName = pd.firstname,
        lastName = pd.lastname,
        dateofbirth = pd.birthdate,
        cardtype = licenseType,
        issuedon = os.date('%d/%m/%Y', now),
        expireson = os.date('%d/%m/%Y', expire),
        expiryTimestamp = expire,
        description = ('%s\nName: %s %s\nDOB: %s\nBerlaku: %s'):format(
            typeLabel(licenseType), pd.firstname, pd.lastname, pd.birthdate, os.date('%d/%m/%Y', expire)
        )
    }
    if Config.LicenseTypes[licenseType].require_photo then
        meta.mugshoturl = photo or ''
    end

    local addOk = exports.ox_inventory:AddItem(tgt.PlayerData.source, tdef.item, 1, meta)
    if not addOk then
        return TriggerClientEvent('QBCore:Notify', src, 'Inventory target penuh.', 'error')
    end

    local issuerCi   = x.PlayerData.charinfo or {}
    local issuerName = ((issuerCi.firstname or '') .. ' ' .. (issuerCi.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
    local issuerCid  = x.PlayerData.citizenid
    local locks      = (Config.Server and Config.Server.DefaultIssueLocks and Config.Server.DefaultIssueLocks[licenseType]) or {}
    local newId = MySQL.insert.await([[
        INSERT INTO sky_license
        (license_type, holder_citizenid, issuer_name, issuer_citizenid, issued_at, expires_at, status, job_lock, min_grade, dept_lock)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        -- Parameter sekarang dalam bentuk list/array, sesuai urutan '?'
        licenseType,
        tgt.PlayerData.citizenid,
        issuerName,
        issuerCid,
        now,
        expire,
        'active',
        locks.job_lock  or nil,
        locks.min_grade or nil,
        locks.dept_lock or nil
    })

    auditLog('issue', src, tgt.PlayerData.citizenid, licenseType, newId, { expires_new = expire }, 'officer_panel')

    TriggerClientEvent('QBCore:Notify', src, ('%s diterbitkan.'):format(typeLabel(licenseType)), 'success')
    TriggerClientEvent('QBCore:Notify', tgt.PlayerData.source, ('Anda menerima %s.'):format(typeLabel(licenseType)), 'success')

    -- Auto-expire one-shot
    local itemName = tdef.item
    SetTimeout(math.max(60, (expire - os.time())) * 1000, function()
        local p = QBCore.Functions.GetPlayerByCitizenId(tgt.PlayerData.citizenid)
        -- update status di DB
        MySQL.update.await('UPDATE sky_license SET status = ? WHERE id = ?', { 'expired', newId })
        auditLog('auto_expire', nil, tgt.PlayerData.citizenid, licenseType, newId, nil, 'system')

        if p then
            local srcHolder = p.PlayerData.source
            local items = exports.ox_inventory:Search(srcHolder, 'slots', itemName)
            if items then
                for slot, it in pairs(items) do
                    if it.metadata and it.metadata.expiryTimestamp and os.time() >= it.metadata.expiryTimestamp then
                        exports.ox_inventory:RemoveItem(srcHolder, itemName, it.count or 1, it.metadata, slot)
                        TriggerClientEvent('QBCore:Notify', srcHolder, ('%s Anda kedaluwarsa dan dihapus.'):format(typeLabel(licenseType)), 'error')
                        auditLog('sync_update', nil, p.PlayerData.citizenid, licenseType, newId, { remove_item = true }, 'system')
                    end
                end
            end
        end
    end)
end)

-- ================== SINKRONISASI SAAT PLAYER MASUK ==================
RegisterNetEvent('QBCore:Server:OnPlayerLoaded')
AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local now = os.time()

    -- ambil lisensi aktif terbaru per jenis
    local active = {}
    local rows = MySQL.query.await(
        'SELECT license_type, MAX(expires_at) AS expires_at FROM sky_license WHERE holder_citizenid = ? AND status = "active" GROUP BY license_type',
        { cid }
    )
    for _, r in ipairs(rows or {}) do active[r.license_type] = r.expires_at end

    -- untuk tiap jenis item yang kita support, sinkronkan
    for code, def in pairs(Config.LicenseTypes) do
        local itemName = def.item
        local items = exports.ox_inventory:Search(src, 'slots', itemName)
        if items and next(items) then
            local expDb = active[code]
            for slot, it in pairs(items) do
                local expItem = it.metadata and it.metadata.expiryTimestamp
                if not expDb or expDb <= now then
                    -- tak ada lisensi aktif → remove item
                    exports.ox_inventory:RemoveItem(src, itemName, it.count or 1, it.metadata, slot)
                    auditLog('sync_update', nil, cid, code, nil, { remove_item = true, reason = 'no_active_license' }, 'system')
                elseif expItem ~= expDb then
                    -- update metadata tanggal
                    local meta = it.metadata or {}
                    meta.expiryTimestamp = expDb
                    meta.expireson = os.date('%d/%m/%Y', expDb)
                    meta.description = meta.description and meta.description:gsub('Berlaku: .+', 'Berlaku: ' .. meta.expireson) or meta.description
                    exports.ox_inventory:RemoveItem(src, itemName, 1, it.metadata, slot)
                    exports.ox_inventory:AddItem(src, itemName, 1, meta)
                    auditLog('sync_update', nil, cid, code, nil, { expiry_sync = expDb }, 'system')
                end
            end
        end
    end
end)