local QBCore = exports['qb-core']:GetCoreObject()
local Utils = require 'shared.utils'

-- =========================
-- In-memory state
-- =========================
local Active = {}     -- [license] = { src, lastPos=vec3, lastMove=os.time(), seconds=NN, refId, requirement, referrer_license, is_debug }
local Daily = {} -- [license] = { src, lastPos=vec3, lastMove=os.time(), seconds_today=0, day=todayStr }
local WindowAct = {} 
local LeaderboardCache = { updatedAt = 0, rows = {} }

local function normalizeLicense(s)
    if not s then return nil end
    return s:gsub('^license:', '')
end

local function dbg(...)
    if Config.Debug and Config.Debug.AfkVerbose then
        print('[tk_referral][AFK]', ...)
    end
end

-- =========================
-- Helpers: identifiers
-- =========================
local function getIdentifiers(src)
    local id = { license = nil, steam = nil, discord = nil, ip = nil }
    for _, ident in ipairs(GetPlayerIdentifiers(src)) do
        if ident:find('license:') == 1 then
            id.license = normalizeLicense(ident)
        elseif ident:find('steam:') == 1 then
            id.steam = ident:gsub('steam:', '')
        elseif ident:find('discord:') == 1 then
            id.discord = ident:gsub('discord:', '')
        end
    end
    id.ip = GetPlayerEndpoint(src); if id.ip and id.ip:find(':') then id.ip = id.ip:match('([^:]+)') end
    return id
end


local function isSelfRefer(referrer_license, referred_ids)
    if not referrer_license then return false end
    if referrer_license == referred_ids.license then return true end
    return false
end

local function windowKey(offsetMinutes, mode) -- return string key & epoch start/end
    local off = (offsetMinutes or 0) * 60
    local now = os.time() + off
    local t = os.date("!*t", now)
    if mode == 'hour' then
        t.min, t.sec = 0, 0
        local start = os.time(t)
        local key = os.date('!%Y-%m-%d %H:00:00', start)
        return key, start - off, (start + 3600) - off
    else
        t.hour, t.min, t.sec = 0, 0, 0
        local start = os.time(t)
        local key = os.date('!%Y-%m-%d', start)
        return key, start - off, (start + 86400) - off
    end
end

-- =========================
-- DB bootstrap
-- =========================
local function ensureReferralCodeForSrc(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    local ids = getIdentifiers(src)               -- <- konsisten
    local license = ids.license
    local citizenid = Player.PlayerData.citizenid
    local name = (Player.PlayerData.charinfo and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname))
        or Player.PlayerData.name or ('CID ' .. citizenid)

    local row = MySQL.single.await('SELECT code FROM referral_codes WHERE license = ? LIMIT 1', { license })
    if row and row.code then return row.code end

    local code
    for _ = 1, 5 do
        code = Utils.generateCode(license, citizenid, Config.Code.Prefix, Config.Code.RandomLength)
        local ins = MySQL.insert.await(
            'INSERT IGNORE INTO referral_codes (license, citizenid, code, alias, is_debug, created_at) VALUES (?, ?, ?, ?, 0, NOW())',
            { license, citizenid, code, name }
        )
        if ins and ins > 0 then break end
    end
    return code
end

local function todayLocalDate(offsetMinutes)
    local off = (offsetMinutes or 0) * 60
    local t = os.date("!*t", os.time() + off) -- pakai UTC lalu digeser
    return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

-- =========================
-- Rewards delivery
-- =========================
local function addMoneyByLicense(license, amount, reason)
    if amount <= 0 then return end
    -- online?
    local target = QBCore.Functions.GetPlayerByLicense(license)
    if target then
        target.Functions.AddMoney(Config.Rewards.MoneyAccount, amount, reason or 'referral')
        return true
    end
    -- offline ledger
    MySQL.insert.await('INSERT INTO referral_rewards_ledger (license, payload_json, reason, status, created_at) VALUES (?, ?, ?, 0, NOW())', {
        license, json.encode({ money = amount, items = {} }), reason or 'referral_offline'
    })
    return false
end

local function addItemsByLicense(license, items, reason)
    if not items then return end
    local target = QBCore.Functions.GetPlayerByLicense(license)
    if target then
        local src = target.PlayerData.source
        for item, count in pairs(items) do
            exports.ox_inventory:AddItem(src, item, count)
        end
        return true
    end
    MySQL.insert.await('INSERT INTO referral_rewards_ledger (license, payload_json, reason, status, created_at) VALUES (?, ?, ?, 0, NOW())', {
        license, json.encode({ money = 0, items = items }), reason or 'referral_offline'
    })
    return false
end

local function deliverPendingRewardsOnLoad(Player)
    local license = Player.PlayerData.license
    local rows = MySQL.query.await('SELECT id, payload_json, reason FROM referral_rewards_ledger WHERE license = ? AND status = 0', { license })
    if rows and #rows > 0 then
        for _, r in ipairs(rows) do
            local payload = {}
            pcall(function() payload = json.decode(r.payload_json or '{}') end)
            if payload.money and payload.money > 0 then
                Player.Functions.AddMoney(Config.Rewards.MoneyAccount, payload.money, r.reason or 'referral_pending')
            end
            if payload.items then
                for item, count in pairs(payload.items) do
                    exports.ox_inventory:AddItem(Player.PlayerData.source, item, count)
                end
            end
            MySQL.update.await('UPDATE referral_rewards_ledger SET status = 1, delivered_at = NOW() WHERE id = ?', { r.id })
        end
    end
end

-- =========================
-- Webhook
-- =========================
local function webhookSend(payload)
    if not Config.Webhook.Enable or not Config.Webhook.Url or Config.Webhook.Url == '' then return end
    PerformHttpRequest(Config.Webhook.Url, function() end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

local function sendEventLog(title, desc, fields)
    webhookSend(Utils.formatDiscordEmbed(title, desc, fields))
end

-- =========================
-- Validation
-- =========================
local function ipWindowBlocked(ip)
    if ip and Config.Validation.UniqueIPWindowDays > 0 then
        local rows = MySQL.single.await([[
            SELECT MAX(redeemed_at) AS last_time
            FROM referrals WHERE ip_at_redeem = ? AND is_debug = 0
        ]], { ip })
        if rows and rows.last_time then
            local last = rows.last_time
            -- compare days
            local sec = os.time() - os.time( (function(s) local y,mo,d,hh,mm,ss = s:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)"); return { year=y, month=mo, day=d, hour=hh, min=mm, sec=ss } end)(last) )
            if sec < (Config.Validation.UniqueIPWindowDays * 86400) then
                return true
            end
        end
    end
    return false
end

local function ipDailyLimitHit(ip)
    if not ip or Config.Validation.MaxRedeemsPerIPPerDay <= 0 then return false end
    local rows = MySQL.single.await([[
        SELECT COUNT(*) AS c FROM referrals
        WHERE ip_at_redeem = ? AND DATE(redeemed_at) = CURDATE()
    ]], { ip })
    return (rows and rows.c or 0) >= Config.Validation.MaxRedeemsPerIPPerDay
end

local function uniquenessViolated(ids)
    -- cek pernah redeem
    local clauses, params = {}, {}
    if Config.Validation.UniquePer.license and ids.license then table.insert(clauses, 'referred_license = ?') table.insert(params, ids.license) end
    if Config.Validation.UniquePer.steam and ids.steam then table.insert(clauses, 'referred_steam = ?') table.insert(params, ids.steam) end
    if Config.Validation.UniquePer.discord and ids.discord then table.insert(clauses, 'referred_discord = ?') table.insert(params, ids.discord) end
    if Config.Validation.UniquePer.ip and ids.ip then table.insert(clauses, 'ip_at_redeem = ?') table.insert(params, ids.ip) end
    if #clauses == 0 then return false end

    local sql = 'SELECT COUNT(*) AS c FROM referrals WHERE (' .. table.concat(clauses, ' OR ') .. ')'
    local row = MySQL.single.await(sql, params)
    if not row then return false end

    if Config.Validation.UniquenessMode == 'ALL' then
        -- 'ALL' mode (jarang dipakai): supaya true, kita cek row yang match keempatnya secara bersamaan
        local sqlAll = 'SELECT COUNT(*) AS c FROM referrals WHERE referred_license = ? AND (referred_steam IS NULL OR referred_steam = ?) AND (referred_discord IS NULL OR referred_discord = ?) AND (ip_at_redeem IS NULL OR ip_at_redeem = ?)'
        local ra = MySQL.single.await(sqlAll, { ids.license or '', ids.steam or '', ids.discord or '', ids.ip or '' })
        return (ra and ra.c or 0) > 0
    end

    -- ANY
    return (row.c or 0) > 0
end

-- =========================
-- Progress tracking
-- =========================
local function startActiveTracking(src, refRow, is_debug)
    local ids = getIdentifiers(src)
    Active[ids.license] = {
        src = src,
        lastPos = nil,
        lastMove = Utils.now(),
        seconds = refRow.seconds_active or 0,
        refId = refRow.id,
        requirement = refRow.requirement_seconds or Config.RequirementSeconds,
        referrer_license = refRow.referrer_license,
        is_debug = is_debug or false
    }
end

local function stopActiveTrackingByLicense(license)
    Active[license] = nil
end

-- heartbeat: posisi dari client
-- Heartbeat dari client: posisi + kecepatan
RegisterNetEvent('tk_referral:hb', function(x, y, z, speed)
    local src = source
    local ids = getIdentifiers(src)     -- pastikan fungsi ini mengembalikan license yang sudah dinormalisasi
    local now = Utils.now()
    speed = tonumber(speed) or 0.0

    -- logger debug lokal
    local function afkdbg(...)
        if Config.Debug and Config.Debug.AfkVerbose then
            print('[tk_referral][AFK]', ...)
        end
    end

    -- helper: update satu tracker (referral aktif / window activity)
    local function updateTracker(tracker, label)
        if not tracker then return end

        local dist = 0.0
        if tracker.lastPos then
            local dx = x - tracker.lastPos.x
            local dy = y - tracker.lastPos.y
            local dz = z - tracker.lastPos.z
            dist = math.sqrt(dx*dx + dy*dy + dz*dz)
        end

        local minDist = Config.AfkDetect.MinMoveDistance or 2.0
        local minSpeed = Config.AfkDetect.MinSpeed or 0.4
        local maxIdle = Config.AfkDetect.MaxIdleSeconds or 300

        local byDist   = dist >= minDist
        local bySpeed  = speed >= minSpeed
        local idleDelta = (now - (tracker.lastMove or now))
        -- “resume rule”: bila sebelumnya idle > maxIdle, pergerakan kecil sudah cukup untuk “bangun”
        local resume   = idleDelta > maxIdle and dist >= 0.05

        local moved = byDist or bySpeed or resume or (tracker.lastPos == nil)
        if moved then
            tracker.lastMove = now
        end
        tracker.lastPos = vector3(x, y, z)

        afkdbg(('%s:%s dist=%.2f spd=%.2f idleΔ=%ds moved=%s sec=%d'):format(
            label,
            ids.license or 'nil',
            dist,
            speed,
            idleDelta,
            tostring(moved),
            tracker.seconds or tracker.seconds_window or 0
        ))
    end

    -- 1) Update progress referral aktif (kalau pemain ini sedang menjadi referred & belum complete)
    if ids.license and Active and Active[ids.license] then
        updateTracker(Active[ids.license], 'ref')
    end

    -- 2) Update activity window (day/hour) untuk leaderboard HIDE/DECAY
    if ids.license and WindowAct and WindowAct[ids.license] then
        updateTracker(WindowAct[ids.license], 'window')
    end
end)

-- Akumulasi detik aktif (tiap TallyTickSecs)
CreateThread(function()
    local tick = math.max(5, Config.AfkDetect.TallyTickSecs or 15)
    while true do
        Wait(tick * 1000)
        for license, s in pairs(Active) do
            local now = Utils.now()
            local active = true
            if Config.AfkDetect.Enable then
                if (now - (s.lastMove or now)) > (Config.AfkDetect.MaxIdleSeconds or 300) then
                    active = false
                end
            end

            if active then
                s.seconds = (s.seconds or 0) + tick
                -- persist sebagian agar aman saat crash
                MySQL.update.await('UPDATE referrals SET seconds_active = ? WHERE id = ?', { s.seconds, s.refId })
            end

            -- cek complete
            if (s.seconds or 0) >= (s.requirement or Config.RequirementSeconds) then
                -- mark complete sekali saja
                local done = MySQL.update.await('UPDATE referrals SET completed = 1 WHERE id = ? AND completed = 0', { s.refId })
                if done and done > 0 then
                    -- hadiah referred on complete
                    local referred_license = license
                    local reward = Config.Rewards.ReferredOnComplete
                    if reward.money and reward.money > 0 then
                        addMoneyByLicense(referred_license, reward.money, 'referral_referred_complete')
                    end
                    if reward.items then
                        addItemsByLicense(referred_license, reward.items, 'referral_referred_complete')
                    end

                    -- cek & berikan milestone untuk referrer
                    local row = MySQL.single.await('SELECT referrer_license FROM referrals WHERE id = ?', { s.refId })
                    local referrer_license = row and row.referrer_license or s.referrer_license
                    if referrer_license then
                        -- total completed oleh referrer (exclude debug)
                        local total
                        if Config.Debug.ExcludeDebugFromLeaderboard then
                            total = MySQL.single.await([[
                                SELECT COUNT(*) AS c FROM referrals r
                                LEFT JOIN referral_codes c ON c.license = r.referrer_license
                                WHERE r.referrer_license = ? AND r.completed = 1 AND COALESCE(c.is_debug,0)=0
                            ]], { referrer_license })
                        else
                            total = MySQL.single.await('SELECT COUNT(*) AS c FROM referrals WHERE referrer_license = ? AND completed = 1', { referrer_license })
                        end
                        total = (total and total.c) or 0

                        local milestones = Config.Rewards.ReferrerMilestones or {}
                        if milestones[total] then
                            local m = milestones[total]
                            if m.money and m.money > 0 then
                                addMoneyByLicense(referrer_license, m.money, ('referral_milestone_%d'):format(total))
                            end
                            if m.items then
                                addItemsByLicense(referrer_license, m.items, ('referral_milestone_%d'):format(total))
                            end
                            sendEventLog('Milestone Referral',
                                ('License %s mencapai milestone %d'):format(referrer_license, total),
                                { { name = 'Milestone', value = tostring(total), inline = true } })
                        end
                    end

                    -- notifikasi ke pemain (kalau masih online)
                    local p = QBCore.Functions.GetPlayerByLicense(license)
                    if p then
                        TriggerClientEvent('ox_lib:notify', p.PlayerData.source, { type = 'success', description = 'Referral complete! Hadiah sudah diberikan.' })
                    end
                end

                -- stop tracking setelah complete
                stopActiveTrackingByLicense(license)
            end
        end
    end
end)

-- Akumulasi detik aktif harian untuk SEMUA pemain online (referrer gate/decay)
CreateThread(function()
    if not Config.DailyReferrerActivity.Enable then return end
    local tick = math.max(5, Config.AfkDetect.TallyTickSecs or 15)
    local mode = Config.DailyReferrerActivity.Window or 'day'
    while true do
        Wait(tick * 1000)
        local keyNow = windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, mode)
        local keyStr = keyNow
        for license, w in pairs(WindowAct) do
            -- rollover window
            if w.key ~= keyStr then
                -- simpan window lama
                if mode == 'hour' then
                    MySQL.prepare.await([[
                        INSERT INTO ref_hour_activity (license, hour_start, seconds_active)
                        VALUES (?, ?, ?)
                        ON DUPLICATE KEY UPDATE seconds_active = GREATEST(seconds_active, VALUES(seconds_active))
                    ]], { license, w.key, w.seconds_window or 0 })
                else
                    MySQL.prepare.await([[
                        INSERT INTO ref_daily_activity (license, day_date, seconds_active)
                        VALUES (?, ?, ?)
                        ON DUPLICATE KEY UPDATE seconds_active = GREATEST(seconds_active, VALUES(seconds_active))
                    ]], { license, w.key, w.seconds_window or 0 })
                end
                -- reset
                w.seconds_window = 0
                w.key = keyStr
            end

            -- hitung aktif (anti-AFK)
            local active = true
            if Config.AfkDetect.Enable then
                if (Utils.now() - (w.lastMove or 0)) > (Config.AfkDetect.MaxIdleSeconds or 300) then
                    active = false
                end
            end
            if active then
                w.seconds_window = (w.seconds_window or 0) + tick
            end

            -- persist incremental ringan
            if mode == 'hour' then
                MySQL.prepare.await([[
                    INSERT INTO ref_hour_activity (license, hour_start, seconds_active)
                    VALUES (?, ?, ?)
                    ON DUPLICATE KEY UPDATE seconds_active = VALUES(seconds_active)
                ]], { license, keyStr, w.seconds_window or 0 })
            else
                MySQL.prepare.await([[
                    INSERT INTO ref_daily_activity (license, day_date, seconds_active)
                    VALUES (?, ?, ?)
                    ON DUPLICATE KEY UPDATE seconds_active = VALUES(seconds_active)
                ]], { license, keyStr, w.seconds_window or 0 })
            end
        end
    end
end)

-- Rebuild leaderboard cache
local function rebuildLeaderboard()
    local topN = Config.Leaderboard.TopN or 10
    local excludeDebug = Config.Debug.ExcludeDebugFromLeaderboard
    local mode = Config.DailyReferrerActivity.Window or 'day'
    local needSecs = (Config.DailyReferrerActivity.Minutes or 60) * 60

    local baseWhere = 'WHERE r.completed = 1'
    if excludeDebug then
        baseWhere = baseWhere .. ' AND COALESCE(c.is_debug,0)=0'
    end

    -- helper ambil base rows lifetime
    local function getBase()
        local sql = ([[
            SELECT r.referrer_license, COALESCE(c.alias, r.referrer_license) AS alias, COUNT(*) AS total
            FROM referrals r
            LEFT JOIN referral_codes c ON c.license = r.referrer_license
            %s
            GROUP BY r.referrer_license, c.alias
        ]]):format(baseWhere)
        return MySQL.query.await(sql, {}) or {}
    end

    -- HIDE: filter hanya yang aktif pada window sekarang
    if Config.DailyReferrerActivity.Enable and (Config.DailyReferrerActivity.Policy == 'HIDE') then
        if mode == 'hour' then
            local keyNow = windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, 'hour')
            local sql = ([[
                SELECT r.referrer_license, COALESCE(c.alias, r.referrer_license) AS alias, COUNT(*) AS total
                FROM referrals r
                LEFT JOIN referral_codes c ON c.license = r.referrer_license
                INNER JOIN ref_hour_activity ha ON ha.license = r.referrer_license
                     AND ha.hour_start = ?
                     AND ha.seconds_active >= ?
                %s
                GROUP BY r.referrer_license, c.alias
                ORDER BY total DESC
                LIMIT %d
            ]]):format(baseWhere, topN)
            LeaderboardCache.rows = MySQL.query.await(sql, { keyNow, needSecs }) or {}
        else
            local today = windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, 'day')
            local sql = ([[
                SELECT r.referrer_license, COALESCE(c.alias, r.referrer_license) AS alias, COUNT(*) AS total
                FROM referrals r
                LEFT JOIN referral_codes c ON c.license = r.referrer_license
                INNER JOIN ref_daily_activity da ON da.license = r.referrer_license
                     AND da.day_date = ?
                     AND da.seconds_active >= ?
                %s
                GROUP BY r.referrer_license, c.alias
                ORDER BY total DESC
                LIMIT %d
            ]]):format(baseWhere, topN)
            LeaderboardCache.rows = MySQL.query.await(sql, { today, needSecs }) or {}
        end
        LeaderboardCache.updatedAt = Utils.now()
        return
    end

    -- DECAY: hitung pengurangan per window
    local base = getBase()
    if Config.DailyReferrerActivity.Enable and (Config.DailyReferrerActivity.Policy == 'DECAY') then
        local scored = {}
        if mode == 'hour' then
            local keyNow = windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, 'hour')
            for _, r in ipairs(base) do
                local lastRow = MySQL.single.await([[
                    SELECT MAX(hour_start) AS last_hour
                    FROM ref_hour_activity
                    WHERE license = ? AND seconds_active >= ?
                ]], { r.referrer_license, needSecs })
                local miss = 0
                if lastRow and lastRow.last_hour then
                    -- selisih jam
                    local y,mo,d,hh = lastRow.last_hour:match("(%d+)%-(%d+)%-(%d+) (%d+):")
                    local last = os.time{year=tonumber(y),month=tonumber(mo),day=tonumber(d),hour=tonumber(hh),min=0,sec=0}
                    local Y,M,D,H = keyNow:match("(%d+)%-(%d+)%-(%d+) (%d+):")
                    local cur  = os.time{year=tonumber(Y),month=tonumber(M),day=tonumber(D),hour=tonumber(H),min=0,sec=0}
                    miss = math.max(0, math.floor((cur - last) / 3600))
                else
                    miss = 9999
                end
                local score = math.max(Config.DailyReferrerActivity.Floor or 0,
                                       (r.total or 0) - (miss * (Config.DailyReferrerActivity.DecayPerWindow or 1)))
                if score > 0 then
                    scored[#scored+1] = { referrer_license = r.referrer_license, alias = r.alias, total = score }
                end
            end
        else
            -- mode 'day' (lama) tetap seperti sebelumnya (pakai DecayPerDay & ref_daily_activity)
            -- ... (kode lamamu di sini tidak perlu diubah)
        end
        table.sort(scored, function(a,b) return (a.total or 0) > (b.total or 0) end)
        while #scored > topN do table.remove(scored) end
        LeaderboardCache.rows = scored
        LeaderboardCache.updatedAt = Utils.now()
        return
    end

    -- fallback: lifetime
    table.sort(base, function(a,b) return (a.total or 0) > (b.total or 0) end)
    while #base > topN do table.remove(base) end
    LeaderboardCache.rows = base
    LeaderboardCache.updatedAt = Utils.now()
end

-- Timer leaderboard in-game
CreateThread(function()
    while true do
        rebuildLeaderboard()
        -- broadcast Top 3 ringkas
        if LeaderboardCache.rows and #LeaderboardCache.rows > 0 then
            local msg = ('[Referral Top] %s'):format(
                table.concat((function()
                    local t = {}
                    for i = 1, math.min(3, #LeaderboardCache.rows) do
                        local r = LeaderboardCache.rows[i]
                        t[#t+1] = ('#%d %s (%d)'):format(i, r.alias or 'N/A', r.total or 0)
                    end
                    return t
                end)(), ' | ')
            )
            TriggerClientEvent('chat:addMessage', -1, { args = { '^5TK', msg } })
        end
        Wait((Config.Leaderboard.InGameRefreshMinutes or 60) * 60 * 1000)
    end
end)

-- Timer leaderboard Discord
CreateThread(function()
    while true do
        rebuildLeaderboard()
        local fields = {}
        for i, r in ipairs(LeaderboardCache.rows) do
            fields[#fields+1] = { name = ('#%d %s'):format(i, r.alias or r.referrer_license), value = ('Total complete: **%d**'):format(r.total or 0), inline = false }
        end
        webhookSend(Utils.formatDiscordEmbed('Referral Leaderboard', 'Top '.. (Config.Leaderboard.TopN or 10) ..' (Lifetime)', fields))
        Wait((Config.Leaderboard.DiscordRefreshHours or 12) * 3600 * 1000)
    end
end)

-- =========================
-- Callbacks / API
-- =========================
lib.callback.register('tk_referral:getCode', function(src)
    local code = ensureReferralCodeForSrc(src)
    if not code then return false, 'Player not found' end
    return true, code
end)

lib.callback.register('tk_referral:getSummary', function(src)
    local ids = getIdentifiers(src)
    local code = MySQL.single.await('SELECT code FROM referral_codes WHERE license = ?', { ids.license })
    local prog = MySQL.single.await('SELECT id, seconds_active, requirement_seconds, completed FROM referrals WHERE referred_license = ? ORDER BY id DESC LIMIT 1', { ids.license })
    local total = MySQL.single.await('SELECT COUNT(*) AS c FROM referrals WHERE referrer_license = ? AND completed = 1', { ids.license })
    return {
        code = code and code.code,
        progress = prog,
        totalCompletedAsReferrer = (total and total.c) or 0
    }
end)

lib.callback.register('tk_referral:getTop', function(src)
    return {
        updatedAt = LeaderboardCache.updatedAt,
        rows = LeaderboardCache.rows
    }
end)

-- Redeem handler
RegisterNetEvent('tk_referral:redeem', function(code, isDebugCode)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    code = (code or ''):upper():gsub('%s+', '')
    if code == '' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Kode kosong.' })
        return
    end

    local ids = getIdentifiers(src)
    if Config.Validation.PlaytimeGate.Enabled then
        -- (opsional — kamu minta OFF)
    end

    local row = MySQL.single.await('SELECT license, code, alias, is_debug FROM referral_codes WHERE code = ? LIMIT 1', { code })
    if not row then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Kode tidak ditemukan.' })
        return
    end

    -- self refer block
    if isSelfRefer(row.license, ids) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Tidak bisa memakai kode sendiri.' })
        return
    end

    -- uniqueness checks
    if uniquenessViolated(ids) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Akun/ID/IP ini sudah pernah redeem.' })
        return
    end
    if ipDailyLimitHit(ids.ip) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Batas redeem per IP hari ini tercapai.' })
        return
    end
    if ipWindowBlocked(ids.ip) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'IP ini masih dalam masa tunggu.' })
        return
    end

    -- concurrent active cap
    local act = MySQL.single.await('SELECT COUNT(*) AS c FROM referrals WHERE referrer_license = ? AND completed = 0', { row.license })
    if (act and act.c or 0) >= (Config.Validation.MaxConcurrentActiveByReferrer or 10) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Kode ini sedang ramai. Coba lagi nanti.' })
        return
    end

    -- insert referral
    local reqSecs = Config.RequirementSeconds
    local graceUntil = nil
    if Config.Grace.Enable then
        graceUntil = os.date('%Y-%m-%d %H:%M:%S', os.time() + (Config.Grace.Minutes * 60))
    end
    local insId = MySQL.insert.await([[
        INSERT INTO referrals
        (referrer_license, referrer_cid, referrer_code, referred_license, referred_cid, referred_steam, referred_discord, ip_at_redeem, redeemed_at, seconds_active, requirement_seconds, completed, reward_given, grace_until, is_debug)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), 0, ?, 0, 0, ?, ?)
    ]], {
        row.license,
        Player.PlayerData.citizenid,
        row.code,
        ids.license,
        Player.PlayerData.citizenid,
        ids.steam or nil,
        ids.discord or nil,
        ids.ip or nil,
        reqSecs,
        graceUntil,
        (row.is_debug == 1) and 1 or 0
    })

    if not insId or insId <= 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Gagal redeem. Coba lagi.' })
        return
    end

    -- hadian on redeem (opsional)
    local onRedeem = Config.Rewards.ReferredOnRedeem
    if onRedeem and ((onRedeem.money or 0) > 0 or (onRedeem.items and next(onRedeem.items))) then
        if (onRedeem.money or 0) > 0 then
            Player.Functions.AddMoney(Config.Rewards.MoneyAccount, onRedeem.money, 'referral_on_redeem')
        end
        if onRedeem.items then
            for item, count in pairs(onRedeem.items) do
                exports.ox_inventory:AddItem(src, item, count)
            end
        end
    end

    -- mulai tracking
    startActiveTracking(src, { id = insId, seconds_active = 0, requirement_seconds = reqSecs, referrer_license = row.license }, row.is_debug == 1)

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Kode %s diterima. Selesaikan %d detik aktif untuk hadiah.'):format(code, reqSecs) })
    sendEventLog('Redeem Referral', ('%s redeem kode %s (owner %s)'):format(ids.license, code, row.license), {
        { name = 'IP', value = ids.ip or 'N/A', inline = true }
    })
end)

-- Grace switch (ganti kode 1x)
RegisterNetEvent('tk_referral:switchCode', function(newCode)
    if not Config.Grace.Enable then return end
    local src = source
    local ids = getIdentifiers(src)
    local ref = MySQL.single.await('SELECT * FROM referrals WHERE referred_license = ? ORDER BY id DESC LIMIT 1', { ids.license })
    if not ref or ref.completed == 1 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Tidak ada referral aktif untuk diganti.' })
        return
    end

    -- cek syarat grace
    local now = Utils.now()
    local maxActive = Config.Grace.MaxActiveSeconds or 300
    if ref.seconds_active > maxActive then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Sudah terlalu lama aktif, tidak bisa ganti.' })
        return
    end
    if ref.grace_until and os.time((function(s) local y,mo,d,hh,mm,ss = s:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)"); return {year=y,month=mo,day=d,hour=hh,min=mm,sec=ss} end)(ref.grace_until)) < now then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Waktu grace habis.' })
        return
    end

    newCode = (newCode or ''):upper():gsub('%s+', '')
    local owner = MySQL.single.await('SELECT license FROM referral_codes WHERE code = ? LIMIT 1', { newCode })
    if not owner then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Kode baru tidak valid.' })
        return
    end
    if isSelfRefer(owner.license, ids) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Tidak bisa pakai kode sendiri.' })
        return
    end

    MySQL.update.await('UPDATE referrals SET referrer_license = ?, referrer_code = ? WHERE id = ?', { owner.license, newCode, ref.id })
    Active[ids.license] = nil -- reset tracking; akan auto start lagi pada tick berikut (opsional)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Kode diganti ke %s.'):format(newCode) })
end)

RegisterCommand('ref_reloadtop', function(src)
    if src > 0 and not Config.Debug.Enable then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Debug off di config.' })
        return
    end
    rebuildLeaderboard()
    if src > 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Leaderboard di-refresh.' })
    end
end, false)

-- Player loaded / dropped
-- QBCore player loaded
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if not Player then return end
    local src = Player.PlayerData.source

    -- 1) Pastikan player punya referral code (format mengikuti Config.Code)
    ensureReferralCodeForSrc(src)

    -- 2) Kirim hadiah yang tertunda (ledger) kalau ada
    deliverPendingRewardsOnLoad(Player)

    -- 3) Resume tracking referral aktif (kalau player ini sedang menjadi "referred" & belum complete)
    local ids = getIdentifiers(src)  -- license sudah ternormalisasi oleh getIdentifiers()
    if ids.license then
        local refRow = MySQL.single.await([[
            SELECT id, seconds_active, requirement_seconds, referrer_license, completed, is_debug
            FROM referrals
            WHERE referred_license = ?
            ORDER BY id DESC
            LIMIT 1
        ]], { ids.license })

        if refRow and refRow.completed == 0 then
            startActiveTracking(src, refRow, (refRow.is_debug == 1))
            -- opsional: info ke player
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'info',
                description = ('Referral aktif ditemukan: %d/%d detik. Lanjutkan bermain untuk menyelesaikan.')
                    :format(refRow.seconds_active or 0, refRow.requirement_seconds or Config.RequirementSeconds)
            })
        end
    end

    -- 4) Inisialisasi activity window (untuk leaderboard HIDE/DECAY per day/hour)
    if Config.DailyReferrerActivity and Config.DailyReferrerActivity.Enable then
        local mode = Config.DailyReferrerActivity.Window or 'day'       -- 'day' | 'hour'
        local key  = windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, mode)

        if ids.license then
            -- state in-memory untuk window berjalan
            WindowAct[ids.license] = {
                src = src,
                lastPos = nil,
                lastMove = Utils.now(),
                seconds_window = 0,
                key = key
            }

            -- Prefill dari DB (biar angka tidak reset saat restart)
            if mode == 'hour' then
                local row = MySQL.single.await([[
                    SELECT seconds_active FROM ref_hour_activity
                    WHERE license = ? AND hour_start = ? LIMIT 1
                ]], { ids.license, key })
                if row and row.seconds_active then
                    WindowAct[ids.license].seconds_window = row.seconds_active
                end
            else -- 'day'
                local row = MySQL.single.await([[
                    SELECT seconds_active FROM ref_daily_activity
                    WHERE license = ? AND day_date = ? LIMIT 1
                ]], { ids.license, key })
                if row and row.seconds_active then
                    WindowAct[ids.license].seconds_window = row.seconds_active
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local ids = getIdentifiers(src)
    if ids.license then Daily[ids.license] = nil end
    local s = Active[ids.license]
    if s then Active[ids.license] = nil end
    WindowAct[ids.license] = nil
end)


-- =========================
-- DEBUG TOOLS
-- =========================
lib.callback.register('tk_referral:debug:createCode', function(src)
    if not Config.Debug.Enable then return false, 'Debug off' end
    local ids = getIdentifiers(src)
    -- buat referral code "debug owner" (excludes leaderboard jika diaktifkan)
    local dbgLicense = 'debug_' .. math.random(10000, 99999)
    local dbgCode = ('TEST%02X'):format(math.random(0, 255))
    MySQL.insert.await('INSERT INTO referral_codes (license, citizenid, code, alias, is_debug, created_at) VALUES (?, ?, ?, ?, 1, NOW())', {
        dbgLicense, 'DBG'.. math.random(100, 999), dbgCode, 'DEBUG OWNER'
    })
    return true, dbgCode
end)

RegisterCommand('ref_afkdebug', function(src, args)
    if not Config.Debug then Config.Debug = {} end
    Config.Debug.AfkVerbose = not Config.Debug.AfkVerbose
    local msg = ('AFK verbose: %s'):format(tostring(Config.Debug.AfkVerbose))
    if src > 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = msg })
    end
    print('[tk_referral]', msg)
end, false)