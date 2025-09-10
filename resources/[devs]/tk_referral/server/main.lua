local QBCore = exports['qb-core']:GetCoreObject()
local Utils  = require('shared.utils')

-- =========================
-- State
-- =========================
local Active = {}        -- [referred_license] = { src, lastPos, lastMove, seconds, refId, requirement, referrer_license, is_debug, _lastPersist }
local WindowAct = {}     -- [license] = { src, lastPos, lastMove, seconds_window, key, _lastPersist }
local LeaderboardCache = { updatedAt = 0, rows = {} }

-- =========================
-- Helpers
-- =========================
local function normalizeLicense(s) if not s then return nil end return s:gsub('^license:','') end

local function getIdentifiers(src)
  local id = { license=nil, steam=nil, discord=nil, ip=nil }
  for _, ident in ipairs(GetPlayerIdentifiers(src)) do
    if ident:find('license:')==1 then id.license = normalizeLicense(ident)
    elseif ident:find('steam:')==1 then id.steam = ident:gsub('steam:','')
    elseif ident:find('discord:')==1 then id.discord = ident:gsub('discord:','') end
  end
  id.ip = GetPlayerEndpoint(src); if id.ip and id.ip:find(':') then id.ip = id.ip:match('([^:]+)') end
  return id
end

local function getPlayerByLicense(license)
  if not license then return nil end
  for _, src in pairs(QBCore.Functions.GetPlayers()) do
    local p = QBCore.Functions.GetPlayer(src)
    if p and normalizeLicense(p.PlayerData.license or '') == license then return p end
  end
  return nil
end

local function windowKey(offsetMinutes, mode)
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

local function dbg(...) if Config.Debug and Config.Debug.AfkVerbose then print('[tk_referral][AFK]', ...) end end

-- Unlock semua claim on-redeem yang eligible (sudah complete) untuk sebuah license
local function unlockEligibleClaimsForLicense(license)
  if not license then return 0 end
  local sql = [[
    UPDATE referral_claims rc
    JOIN referrals r
      ON rc.license = r.referred_license
     AND rc.reason  = CONCAT('referred_on_redeem:', r.id)
  SET rc.status = 0
  WHERE rc.status = -1
    AND r.completed = 1
    AND rc.license = ?
  ]]
  local ok = MySQL.update.await(sql, { license }) or 0
  return ok
end

-- =========================
-- Codes
-- =========================
local function ensureReferralCodeForSrc(src)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return nil end
  local ids = getIdentifiers(src); local license = ids.license; if not license then return nil end

  local citizenid = Player.PlayerData.citizenid
  local alias = (Player.PlayerData.charinfo and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname))
                or Player.PlayerData.name or ('CID '..citizenid)

  local row = MySQL.single.await('SELECT code FROM referral_codes WHERE license = ? LIMIT 1', { license })
  if row and row.code then return row.code end

  local code
  for _=1,5 do
    code = Utils.generateCode(license, citizenid, Config.Code.Prefix, Config.Code.RandomLength)
    local ins = MySQL.insert.await(
      'INSERT IGNORE INTO referral_codes (license, citizenid, code, alias, is_debug, created_at) VALUES (?,?,?,?,0,NOW())',
      { license, citizenid, code, alias }
    )
    if ins and ins > 0 then break end
  end
  return code
end

-- =========================
-- Claims (Manual Reward System)
-- =========================
-- status: -1 = locked (tidak tampil), 0 = unlocked (bisa di-claim), 1 = claimed, 2 = processing
local function enqueueClaim(license, payload, reason, status)
  return MySQL.insert.await([[
    INSERT INTO referral_claims (license, payload_json, reason, status, created_at)
    VALUES (?, ?, ?, ?, NOW())
  ]], { license, json.encode(payload or {}), reason or 'reward', status or 0 })
end

local function grantPayloadToPlayer(Player, payload, reason)
  payload = payload or {}
  if (payload.money or 0) > 0 then
    Player.Functions.AddMoney(Config.Rewards.MoneyAccount, payload.money, reason or 'referral_claim')
  end
  if payload.items then
    for item, count in pairs(payload.items) do
      exports.ox_inventory:AddItem(Player.PlayerData.source, item, count or 1)
    end
  end
end

-- =========================
-- Validation (Opsi A)
-- =========================
local function ipDailyLimitHit(ip)
  if not ip or (Config.Validation.MaxRedeemsPerIPPerDay or 0) <= 0 then return false end
  local row = MySQL.single.await([[
    SELECT COUNT(*) AS c FROM referrals
    WHERE ip_at_redeem = ? AND DATE(redeemed_at) = CURDATE()
  ]], { ip })
  return ((row and row.c) or 0) >= (Config.Validation.MaxRedeemsPerIPPerDay or 0)
end

-- return: blocked:boolean, remainingSec:number
-- return: blocked:boolean, remainingSec:number
local function ipWindowBlocked(ip)
  local secs = Config.Validation.UniqueIPWindowSeconds or 0
  local days = Config.Validation.UniqueIPWindowDays or 0
  if not ip or (secs <= 0 and days <= 0) then return false, 0 end

  local row = MySQL.single.await([[
    SELECT UNIX_TIMESTAMP(NOW()) AS now_ts,
           UNIX_TIMESTAMP(MAX(redeemed_at)) AS last_ts
    FROM referrals
    WHERE ip_at_redeem = ? AND is_debug = 0
  ]], { ip })

  if not row or not row.last_ts then
    return false, 0
  end

  local window = (secs > 0) and secs or (days * 86400)
  local diff   = (row.now_ts or os.time()) - (row.last_ts or 0)
  local remaining = window - diff
  if remaining > 0 then
    return true, remaining
  else
    return false, 0
  end
end


local function overActiveCapForReferrer(referrer_license)
  local act = MySQL.single.await('SELECT COUNT(*) AS c FROM referrals WHERE referrer_license = ? AND completed = 0', { referrer_license })
  return ((act and act.c) or 0) >= (Config.Validation.MaxConcurrentActiveByReferrer or 10)
end

-- =========================
-- Active tracking (1 aktif per referred = baris terbaru)
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
    is_debug = is_debug or false,
    _lastPersist = Utils.now()
  }
end
local function stopActiveTrackingByLicense(license) Active[license] = nil end

-- =========================
-- Leaderboard (HIDE/DECAY/Lifetime + fallback)
-- =========================
local function rebuildLeaderboard()
  local topN = Config.Leaderboard.TopN or 10
  local excludeDebug = Config.Debug.ExcludeDebugFromLeaderboard
  local mode = (Config.DailyReferrerActivity and Config.DailyReferrerActivity.Window) or 'day'
  local needSecs = ((Config.DailyReferrerActivity and Config.DailyReferrerActivity.Minutes) or 60) * 60

  local baseWhere = 'WHERE r.completed = 1'
  if excludeDebug then baseWhere = baseWhere .. ' AND COALESCE(c.is_debug,0)=0' end

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

  local function fallbackIfEmpty()
    if not Config.Leaderboard.FallbackToLifetimeIfEmpty then return end
    if #(LeaderboardCache.rows or {}) > 0 then return end
    local base = getBase()
    table.sort(base, function(a,b) return (a.total or 0) > (b.total or 0) end)
    while #base > topN do table.remove(base) end
    LeaderboardCache.rows = base
  end

  -- HIDE
  if Config.DailyReferrerActivity and Config.DailyReferrerActivity.Enable and Config.DailyReferrerActivity.Policy == 'HIDE' then
    if mode == 'hour' then
      local keyStr = (function() local k=windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, 'hour'); return (type(k)=='table') and k[1] or k end)()
      local sql = ([[
        SELECT r.referrer_license, COALESCE(c.alias, r.referrer_license) AS alias, COUNT(*) AS total
        FROM referrals r
        LEFT JOIN referral_codes c ON c.license = r.referrer_license
        INNER JOIN ref_hour_activity ha ON ha.license = r.referrer_license
             AND ha.hour_start = ? AND ha.seconds_active >= ?
        %s
        GROUP BY r.referrer_license, c.alias
        ORDER BY total DESC
        LIMIT %d
      ]]):format(baseWhere, topN)
      LeaderboardCache.rows = MySQL.query.await(sql, { keyStr, needSecs }) or {}
      LeaderboardCache.updatedAt = Utils.now()
      fallbackIfEmpty()
      return
    else
      local dayStr = (function() local k=windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, 'day'); return (type(k)=='table') and k[1] or k end)()
      local sql = ([[
        SELECT r.referrer_license, COALESCE(c.alias, r.referrer_license) AS alias, COUNT(*) AS total
        FROM referrals r
        LEFT JOIN referral_codes c ON c.license = r.referrer_license
        INNER JOIN ref_daily_activity da ON da.license = r.referrer_license
             AND da.day_date = ? AND da.seconds_active >= ?
        %s
        GROUP BY r.referrer_license, c.alias
        ORDER BY total DESC
        LIMIT %d
      ]]):format(baseWhere, topN)
      LeaderboardCache.rows = MySQL.query.await(sql, { dayStr, needSecs }) or {}
      LeaderboardCache.updatedAt = Utils.now()
      fallbackIfEmpty()
      return
    end
  end

  -- DECAY
  local base = getBase()
  if Config.DailyReferrerActivity and Config.DailyReferrerActivity.Enable and Config.DailyReferrerActivity.Policy == 'DECAY' then
    local scored = {}
    if mode == 'hour' then
      local _, keyStartEpoch = windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, 'hour')
      for _, r in ipairs(base) do
        local row = MySQL.single.await([[
          SELECT UNIX_TIMESTAMP(MAX(hour_start)) AS last_ts
          FROM ref_hour_activity
          WHERE license = ? AND seconds_active >= ?
        ]], { r.referrer_license, needSecs })
        local last_ts = (row and (row.last_ts or row.ts or row['UNIX_TIMESTAMP(MAX(hour_start))'])) or nil
        local miss = last_ts and math.max(0, math.floor((keyStartEpoch - last_ts) / 3600)) or 9999
        local score = math.max(Config.DailyReferrerActivity.Floor or 0, (r.total or 0) - (miss * (Config.DailyReferrerActivity.DecayPerWindow or 1)))
        if score > 0 then scored[#scored+1] = { referrer_license=r.referrer_license, alias=r.alias, total=score } end
      end
    else
      local _, dayStartEpoch = windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, 'day')
      for _, r in ipairs(base) do
        local row = MySQL.single.await([[
          SELECT MAX(day_date) AS last_day
          FROM ref_daily_activity
          WHERE license = ? AND seconds_active >= ?
        ]], { r.referrer_license, needSecs })
        local miss = 9999
        if row and row.last_day then
          local y,mo,d = tostring(row.last_day):match("(%d+)%-(%d+)%-(%d+)")
          if y then
            local last = os.time{year=tonumber(y),month=tonumber(mo),day=tonumber(d),hour=0,min=0,sec=0}
            miss = math.max(0, math.floor((dayStartEpoch - last)/86400))
          end
        end
        local score = math.max(Config.DailyReferrerActivity.Floor or 0, (r.total or 0) - (miss * (Config.DailyReferrerActivity.DecayPerDay or 1)))
        if score > 0 then scored[#scored+1] = { referrer_license=r.referrer_license, alias=r.alias, total=score } end
      end
    end
    table.sort(scored, function(a,b) return (a.total or 0) > (b.total or 0) end)
    while #scored > topN do table.remove(scored) end
    LeaderboardCache.rows = scored
    LeaderboardCache.updatedAt = Utils.now()
    return
  end

  -- Lifetime
  table.sort(base, function(a,b) return (a.total or 0) > (b.total or 0) end)
  while #base > topN do table.remove(base) end
  LeaderboardCache.rows = base
  LeaderboardCache.updatedAt = Utils.now()
end

-- =========================
-- Threads
-- =========================
-- 1) Tally progress (flush periodik) + unlock/claims saat complete
CreateThread(function()
  local tick = math.max(5, Config.AfkDetect.TallyTickSecs or 15)
  while true do
    Wait(tick * 1000)
    local now = Utils.now()
    for license, s in pairs(Active) do
      local active = true
      if Config.AfkDetect.Enable then
        if (now - (s.lastMove or now)) > (Config.AfkDetect.MaxIdleSeconds or 300) then active = false end
      end
      if active then s.seconds = (s.seconds or 0) + tick end

      -- flush progress
      s._lastPersist = s._lastPersist or now
      if (now - s._lastPersist) >= (Config.Persistence.ReferralFlushSecs or tick) then
        MySQL.update.await('UPDATE referrals SET seconds_active = ? WHERE id = ?', { s.seconds or 0, s.refId })
        s._lastPersist = now
      end

      -- complete?
      if (s.seconds or 0) >= (s.requirement or Config.RequirementSeconds) then
        -- persist terakhir
        MySQL.update.await('UPDATE referrals SET seconds_active = ? WHERE id = ?', { s.seconds or 0, s.refId })
        MySQL.update.await('UPDATE referrals SET completed = 1 WHERE id = ? AND completed = 0', { s.refId })

        local row = MySQL.single.await('SELECT reward_given, referrer_license, referred_license FROM referrals WHERE id = ?', { s.refId })
        if row and tonumber(row.reward_given or 0) == 0 then
          -- 1) Claim untuk referred (ON-COMPLETE)
          local reward = Config.Rewards.ReferredOnComplete or {}
          if ((reward.money or 0) > 0) or (reward.items and next(reward.items)) then
            enqueueClaim(row.referred_license, { money = reward.money or 0, items = reward.items or {} }, 'referred_complete', 0)
          end

          -- 2) Unlock claim on-redeem (jika ada & masih locked)
          MySQL.update.await([[
            UPDATE referral_claims
            SET status = 0
            WHERE license = ? AND reason = ? AND status = -1
          ]], { row.referred_license, ('referred_on_redeem:%d'):format(s.refId) })

          -- 3) Milestone → claim untuk referrer
          local referrer_license = row.referrer_license
          if referrer_license then
            local milestones = Config.Rewards.ReferrerMilestones or {}
            local total
            if Config.Debug.ExcludeDebugFromMilestones then
              total = MySQL.single.await([[
                SELECT COUNT(*) AS c FROM referrals r
                LEFT JOIN referral_codes c ON c.license = r.referrer_license
                WHERE r.referrer_license = ? AND r.completed = 1 AND COALESCE(c.is_debug,0)=0
              ]], { referrer_license })
            else
              total = MySQL.single.await('SELECT COUNT(*) AS c FROM referrals WHERE referrer_license = ? AND completed = 1', { referrer_license })
            end
            total = (total and total.c) or 0
            local m = milestones[total]
            if m and (((m.money or 0) > 0) or (m.items and next(m.items))) then
              enqueueClaim(referrer_license, { money = m.money or 0, items = m.items or {} }, ('milestone_%d'):format(total), 0)
            end
          end

          -- tandai claims dibuat
          MySQL.update.await('UPDATE referrals SET reward_given = 1 WHERE id = ?', { s.refId })
          rebuildLeaderboard()

          local p = getPlayerByLicense(license)
          if p then TriggerClientEvent('ox_lib:notify', p.PlayerData.source, { type = 'success', description = 'Referral complete! Buka menu Claim untuk ambil hadiah.' }) end
        end

        Active[license] = nil
      end
    end
  end
end)

-- 2) Window activity (flush periodik)
CreateThread(function()
  if not Config.DailyReferrerActivity or not Config.DailyReferrerActivity.Enable then return end
  local tick = math.max(5, Config.AfkDetect.TallyTickSecs or 15)
  local mode = Config.DailyReferrerActivity.Window or 'day'
  while true do
    Wait(tick * 1000)
    local keyStr = (function() local k=windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, mode); return (type(k)=='table') and k[1] or k end)()
    for lic, w in pairs(WindowAct) do
      -- rollover
      if w.key ~= keyStr then
        if mode == 'hour' then
          MySQL.prepare.await([[
            INSERT INTO ref_hour_activity (license, hour_start, seconds_active)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE seconds_active = GREATEST(seconds_active, VALUES(seconds_active))
          ]], { lic, w.key, w.seconds_window or 0 })
        else
          MySQL.prepare.await([[
            INSERT INTO ref_daily_activity (license, day_date, seconds_active)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE seconds_active = GREATEST(seconds_active, VALUES(seconds_active))
          ]], { lic, w.key, w.seconds_window or 0 })
        end
        w.seconds_window = 0; w.key = keyStr; w._lastPersist = Utils.now()
      end

      -- aktif?
      local active = true
      if Config.AfkDetect.Enable then
        if (Utils.now() - (w.lastMove or 0)) > (Config.AfkDetect.MaxIdleSeconds or 300) then active = false end
      end
      if active then w.seconds_window = (w.seconds_window or 0) + tick end

      -- flush periodik
      w._lastPersist = w._lastPersist or Utils.now()
      if (Utils.now() - w._lastPersist) >= (Config.Persistence.WindowFlushSecs or 60) then
        if mode == 'hour' then
          MySQL.prepare.await([[
            INSERT INTO ref_hour_activity (license, hour_start, seconds_active)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE seconds_active = VALUES(seconds_active)
          ]], { lic, keyStr, w.seconds_window or 0 })
        else
          MySQL.prepare.await([[
            INSERT INTO ref_daily_activity (license, day_date, seconds_active)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE seconds_active = VALUES(seconds_active)
          ]], { lic, keyStr, w.seconds_window or 0 })
        end
        w._lastPersist = Utils.now()
      end
    end
  end
end)

-- 3) Leaderboard broadcasts
CreateThread(function()
  while true do
    rebuildLeaderboard()
    if LeaderboardCache.rows and #LeaderboardCache.rows > 0 then
      local top = {}
      for i = 1, math.min(3, #LeaderboardCache.rows) do
        local r = LeaderboardCache.rows[i]
        top[#top+1] = ('#%d %s (%d)'):format(i, r.alias or 'N/A', r.total or 0)
      end
      TriggerClientEvent('chat:addMessage', -1, { args = { '^5TK', '[Referral Top] ' .. table.concat(top, ' | ') } })
    end
    Wait((Config.Leaderboard.InGameRefreshMinutes or 60) * 60000)
  end
end)

CreateThread(function()
  while true do
    rebuildLeaderboard()
    local fields = {}
    for i, r in ipairs(LeaderboardCache.rows) do
      fields[#fields+1] = { name = ('#%d %s'):format(i, r.alias or r.referrer_license), value = ('Total complete: **%d**'):format(r.total or 0), inline = false }
    end
    local payload = Utils.formatDiscordEmbed('Referral Leaderboard', 'Top '..(Config.Leaderboard.TopN or 10), fields)
    if Config.Webhook and Config.Webhook.Enable and Config.Webhook.Url and Config.Webhook.Url ~= '' then
      PerformHttpRequest(Config.Webhook.Url, function() end, 'POST', json.encode(payload), { ['Content-Type']='application/json' })
    end
    Wait((Config.Leaderboard.DiscordRefreshHours or 12) * 3600 * 1000)
  end
end)

-- 4) Repair worker (buat claim yang belum, unlock locked on-redeem)
CreateThread(function()
  while true do
    Wait(60 * 1000)
    local rows = MySQL.query.await([[
      SELECT id, referred_license, referrer_license
      FROM referrals
      WHERE completed = 1 AND reward_given = 0
      ORDER BY id DESC LIMIT 50
    ]], {})
    if rows and #rows > 0 then
      for _, r in ipairs(rows) do
        -- referred complete claim
        local reward = Config.Rewards.ReferredOnComplete or {}
        if ((reward.money or 0) > 0) or (reward.items and next(reward.items)) then
          enqueueClaim(r.referred_license, { money = reward.money or 0, items = reward.items or {} }, 'referred_complete', 0)
        end
        -- unlock locked on-redeem
        MySQL.update.await([[
          UPDATE referral_claims
          SET status = 0
          WHERE license = ? AND reason = ? AND status = -1
        ]], { r.referred_license, ('referred_on_redeem:%d'):format(r.id) })
        -- milestone referrer
        local milestones = Config.Rewards.ReferrerMilestones or {}
        local total = MySQL.single.await('SELECT COUNT(*) AS c FROM referrals WHERE referrer_license = ? AND completed = 1', { r.referrer_license })
        total = (total and total.c) or 0
        local m = milestones[total]
        if m and (((m.money or 0) > 0) or (m.items and next(m.items))) then
          enqueueClaim(r.referrer_license, { money = m.money or 0, items = m.items or {} }, ('milestone_%d'):format(total), 0)
        end

        MySQL.update.await('UPDATE referrals SET reward_given = 1 WHERE id = ?', { r.id })
      end
      rebuildLeaderboard()
    end
  end
end)

-- 5) Rebuild on resource start
AddEventHandler('onResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  CreateThread(function()
    Wait(2500) -- tunggu oxmysql siap
    rebuildLeaderboard()
    print(('[tk_referral] Leaderboard rebuilt on start. rows=%d'):format(#(LeaderboardCache.rows or {})))
  end)
end)

-- =========================
-- Heartbeat (AFK)
-- =========================
RegisterNetEvent('tk_referral:hb', function(x, y, z, speed)
  local src = source
  local ids = getIdentifiers(src)
  local now = Utils.now()
  local spd = tonumber(speed) or 0.0

  local function updateTracker(tr, label)
    if not tr then return end
    local dist=0.0
    if tr.lastPos then
      local dx,dy,dz = x-tr.lastPos.x, y-tr.lastPos.y, z-tr.lastPos.z
      dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    end
    local minDist = Config.AfkDetect.MinMoveDistance or 2.0
    local minSpeed= Config.AfkDetect.MinSpeed or 0.4
    local maxIdle = Config.AfkDetect.MaxIdleSeconds or 300
    local byDist  = dist >= minDist
    local bySpeed = spd >= minSpeed
    local idle  = (now - (tr.lastMove or now))
    local resume  = idle> maxIdle and dist >= 0.05
    local moved = byDist or bySpeed or resume or (tr.lastPos == nil)
    if moved then tr.lastMove = now end
    tr.lastPos = vector3(x,y,z)
    dbg(('%s:%s dist=%.2f spd=%.2f idle=%ds moved=%s sec=%d'):format(label, ids.license or 'nil', dist, spd, idle, tostring(moved), tr.seconds or tr.seconds_window or 0))
  end

  if ids.license and Active[ids.license] then updateTracker(Active[ids.license], 'ref') end
  if ids.license and WindowAct[ids.license] then updateTracker(WindowAct[ids.license], 'window') end
end)

-- =========================
-- Callbacks / Menus
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
  local total= MySQL.single.await('SELECT COUNT(*) AS c FROM referrals WHERE referrer_license = ? AND completed = 1', { ids.license })
  return { code = code and code.code, progress = prog, totalCompletedAsReferrer = (total and total.c) or 0 }
end)

lib.callback.register('tk_referral:getTop', function(src)
  return { updatedAt = LeaderboardCache.updatedAt, rows = LeaderboardCache.rows }
end)

-- Auto-unlock sebelum tampilkan list; list hanya UNLOCKED (status=0)
lib.callback.register('tk_referral:getClaims', function(src, kind)
  local ids = getIdentifiers(src)
  unlockEligibleClaimsForLicense(ids.license)

  local rows = MySQL.query.await(
    'SELECT id, payload_json, reason FROM referral_claims WHERE license = ? AND status = 0 ORDER BY id ASC',
    { ids.license }
  ) or {}

  local resp = { count = 0, items = {} }
  for _, r in ipairs(rows) do
    local isReferred = tostring(r.reason):find('^referred_') ~= nil
    local target = (kind=='referred') and isReferred or ((kind=='referrer') and (not isReferred))
    if target then
      local preview = ''
      local payload = {}; pcall(function() payload = json.decode(r.payload_json or '{}') end)
      if (payload.money or 0) > 0 then preview = preview .. ('Money: %d  '):format(payload.money) end
      if payload.items then
        local parts = {}; for item, cnt in pairs(payload.items) do parts[#parts+1] = (item..' x'..tostring(cnt)) end
        if #parts>0 then preview = preview .. 'Items: ' .. table.concat(parts, ', ') end
      end
      resp.items[#resp.items+1] = { id = r.id, reason = r.reason, preview = preview }
      resp.count = resp.count + 1
    end
  end
  return resp
end)

-- Atomic claim (unlock on-demand jika kebetulan masih locked)
RegisterNetEvent('tk_referral:claimOne', function(claimId)
  local src = source
  local ids = getIdentifiers(src)
  local row = MySQL.single.await('SELECT id, license, payload_json, reason, status FROM referral_claims WHERE id = ? LIMIT 1', { claimId })
  if not row or row.license ~= ids.license then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Claim tidak valid.' }); return
  end

  if tonumber(row.status or -2) == -1 then
    local refId = tonumber(tostring(row.reason):match('^referred_on_redeem:(%d+)$') or '')
    if refId then
      local r = MySQL.single.await('SELECT completed FROM referrals WHERE id = ?', { refId })
      if r and tonumber(r.completed or 0) == 1 then
        MySQL.update.await('UPDATE referral_claims SET status = 0 WHERE id = ? AND status = -1', { row.id })
        row = MySQL.single.await('SELECT id, license, payload_json, reason, status FROM referral_claims WHERE id = ? LIMIT 1', { claimId })
      end
    end
  end

  if tonumber(row.status or -2) ~= 0 then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Claim tidak valid / belum terbuka.' }); return
  end

  -- 0 -> 2 (processing) untuk atomicity
  local updated = MySQL.update.await('UPDATE referral_claims SET status = 2 WHERE id = ? AND status = 0', { row.id })
  if (updated or 0) == 0 then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Claim sedang diproses / sudah diambil.' }); return
  end

  local p = QBCore.Functions.GetPlayer(src)
  if not p then
    MySQL.update.await('UPDATE referral_claims SET status = 0 WHERE id = ? AND status = 2', { row.id })
    return
  end

  local payload = {}; pcall(function() payload = json.decode(row.payload_json or '{}') end)
  grantPayloadToPlayer(p, payload, row.reason)
  MySQL.update.await('UPDATE referral_claims SET status = 1, claimed_at = NOW() WHERE id = ?', { row.id })
  TriggerClientEvent('ox_lib:notify', src, { type='success', description='Reward berhasil di-claim.' })
end)

RegisterNetEvent('tk_referral:claimAll', function(kind)
  local src = source
  local ids = getIdentifiers(src)
  unlockEligibleClaimsForLicense(ids.license)

  local rows = MySQL.query.await('SELECT id, payload_json, reason FROM referral_claims WHERE license = ? AND status = 0 ORDER BY id ASC', { ids.license }) or {}
  if #rows == 0 then TriggerClientEvent('ox_lib:notify', src, { type='info', description='Tidak ada claim.' }); return end

  local p = QBCore.Functions.GetPlayer(src); if not p then return end
  local claimed = 0
  for _, r in ipairs(rows) do
    local isReferred = tostring(r.reason):find('^referred_') ~= nil
    local target = (kind=='referred') and isReferred or ((kind=='referrer') and (not isReferred))
    if target then
      local upd = MySQL.update.await('UPDATE referral_claims SET status = 2 WHERE id = ? AND status = 0', { r.id })
      if (upd or 0) > 0 then
        local payload = {}; pcall(function() payload = json.decode(r.payload_json or '{}') end)
        grantPayloadToPlayer(p, payload, r.reason)
        MySQL.update.await('UPDATE referral_claims SET status = 1, claimed_at = NOW() WHERE id = ?', { r.id })
        claimed = claimed + 1
      end
    end
  end
  TriggerClientEvent('ox_lib:notify', src, { type='success', description=('Claimed %d rewards.'):format(claimed) })
end)

-- =========================
-- Redeem / Switch
-- =========================
RegisterNetEvent('tk_referral:redeem', function(code)
  local src = source
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return end

  code = (code or ''):upper():gsub('%s+','')
  if code == '' then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Kode kosong.' }); return
  end

  local ids = getIdentifiers(src)
  local row = MySQL.single.await('SELECT license, code, alias, is_debug FROM referral_codes WHERE code = ? LIMIT 1', { code })
  if not row then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Kode tidak ditemukan.' }); return
  end

  local isSelf = (row.license == ids.license)
  local allowSelfDebug = (Config.Debug and Config.Debug.Enable and Config.Debug.AllowSelfRedeem)
  if isSelf and not allowSelfDebug then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Tidak bisa memakai kode sendiri.' }); return
  end

  -- Anti-abuse IP (skip bila self+debug)
  local bypassAntiAbuse = (isSelf and allowSelfDebug)
  if not bypassAntiAbuse then
    if ipDailyLimitHit(ids.ip) then
      TriggerClientEvent('ox_lib:notify', src, { type='error', description='Batas redeem per IP hari ini tercapai.' })
      return
    end

    local blocked, remain = ipWindowBlocked(ids.ip)
    if blocked then
      local h = math.floor(remain / 3600)
      local m = math.ceil((remain % 3600) / 60)
      if h > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
          type='error',
          description = ('IP ini masih dalam masa tunggu. Coba lagi dalam %d jam %d menit.'):format(h, m)
        })
      else
        if m < 1 then m = 1 end
        TriggerClientEvent('ox_lib:notify', src, {
          type='error',
          description = ('IP ini masih dalam masa tunggu. Coba lagi dalam %d menit.'):format(m)
        })
      end
      return
    end
  end

  if overActiveCapForReferrer(row.license) then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Kode ini sedang ramai. Coba lagi nanti.' }); return
  end

  local reqSecs = Config.RequirementSeconds
  local graceUntil = nil
  if Config.Grace.Enable then
    graceUntil = os.date('%Y-%m-%d %H:%M:%S', os.time() + (Config.Grace.Minutes * 60))
  end

  local is_debug_flag = (((row.is_debug or 0) == 1) or bypassAntiAbuse) and 1 or 0

  local insId = MySQL.insert.await([[
    INSERT INTO referrals
    (referrer_license, referrer_cid, referrer_code, referred_license, referred_cid, referred_steam, referred_discord, ip_at_redeem, redeemed_at,
     seconds_active, requirement_seconds, completed, reward_given, grace_until, is_debug)
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
    is_debug_flag
  })
  if not insId or insId <= 0 then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Gagal redeem. Coba lagi.' }); return
  end

  -- Hadiah on-redeem → claim LOCKED (baru kebuka saat complete)
  local onRedeem = Config.Rewards.ReferredOnRedeem
  if onRedeem and ((onRedeem.money or 0) > 0 or (onRedeem.items and next(onRedeem.items))) and Config.Rewards.LockOnRedeemUntilComplete then
    enqueueClaim(ids.license,
      { money = onRedeem.money or 0, items = onRedeem.items or {} },
      ('referred_on_redeem:%d'):format(insId),
      -1
    )
    TriggerClientEvent('ox_lib:notify', src, { type='info', description='Hadiah on-redeem akan bisa di-claim setelah complete.' })
  end

  -- Jadikan referral TERBARU sebagai aktif (override yang lama)
  Active[ids.license] = nil
  startActiveTracking(src, { id = insId, seconds_active = 0, requirement_seconds = reqSecs, referrer_license = row.license }, is_debug_flag == 1)

  local msg = ('Kode %s diterima. Main %d detik untuk complete.'):format(code, reqSecs)
  if bypassAntiAbuse then msg = msg .. ' (DEBUG: self-redeem diizinkan)' end
  TriggerClientEvent('ox_lib:notify', src, { type='success', description = msg })
end)

RegisterNetEvent('tk_referral:switchCode', function(newCode)
  if not Config.Grace.Enable then return end
  local src = source
  local ids = getIdentifiers(src)
  local ref = MySQL.single.await('SELECT * FROM referrals WHERE referred_license = ? ORDER BY id DESC LIMIT 1', { ids.license })
  if not ref or ref.completed == 1 then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Tidak ada referral aktif untuk diganti.' }); return
  end
  local now = Utils.now()
  if (ref.seconds_active or 0) > (Config.Grace.MaxActiveSeconds or 300) then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Sudah terlalu lama aktif, tidak bisa ganti.' }); return
  end
  if ref.grace_until then
    local y,mo,d,hh,mm,ss = ref.grace_until:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
    if y then
      local t = os.time{year=tonumber(y),month=tonumber(mo),day=tonumber(d),hour=tonumber(hh),min=tonumber(mm),sec=tonumber(ss)}
      if now > t then TriggerClientEvent('ox_lib:notify', src, { type='error', description='Waktu grace habis.' }); return end
    end
  end

  newCode = (newCode or ''):upper():gsub('%s+','')
  local owner = MySQL.single.await('SELECT license FROM referral_codes WHERE code = ? LIMIT 1', { newCode })
  if not owner or owner.license == ids.license then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Kode baru tidak valid.' }); return
  end

  MySQL.update.await('UPDATE referrals SET referrer_license = ?, referrer_code = ? WHERE id = ?', { owner.license, newCode, ref.id })
  Active[ids.license] = nil
  TriggerClientEvent('ox_lib:notify', src, { type='success', description=('Kode diganti ke %s.'):format(newCode) })
end)

-- =========================
-- Player lifecycle
-- =========================
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
  if not Player then return end
  local src = Player.PlayerData.source
  ensureReferralCodeForSrc(src)

  local ids = getIdentifiers(src)
  unlockEligibleClaimsForLicense(ids.license) -- pastikan klaim yang eligible sudah terbuka

  local c1 = MySQL.single.await('SELECT COUNT(*) AS c FROM referral_claims WHERE license = ? AND status = 0', { ids.license })
  local pending = (c1 and c1.c) or 0
  if pending > 0 then
    TriggerClientEvent('ox_lib:notify', src, { type='info', description=('Ada %d reward belum di-claim (buka /ref → Claim).'):format(pending) })
  end

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
      TriggerClientEvent('ox_lib:notify', src, { type='info', description=('Referral aktif: %d/%d detik.'):format(refRow.seconds_active or 0, refRow.requirement_seconds or Config.RequirementSeconds) })
    end

    if Config.DailyReferrerActivity and Config.DailyReferrerActivity.Enable then
      local mode = Config.DailyReferrerActivity.Window or 'day'
      local key = (function() local k=windowKey(Config.DailyReferrerActivity.TimezoneOffsetMinutes or 420, mode); return (type(k)=='table') and k[1] or k end)()
      WindowAct[ids.license] = { src = src, lastPos = nil, lastMove = Utils.now(), seconds_window=0, key=key, _lastPersist = Utils.now() }
      if mode=='hour' then
        local row = MySQL.single.await('SELECT seconds_active FROM ref_hour_activity WHERE license=? AND hour_start=? LIMIT 1', { ids.license, key })
        if row and row.seconds_active then WindowAct[ids.license].seconds_window = row.seconds_active end
      else
        local row = MySQL.single.await('SELECT seconds_active FROM ref_daily_activity WHERE license=? AND day_date=? LIMIT 1', { ids.license, key })
        if row and row.seconds_active then WindowAct[ids.license].seconds_window = row.seconds_active end
      end
    end
  end
end)

AddEventHandler('playerDropped', function()
  local src = source
  local ids = getIdentifiers(src)
  if not ids.license then return end

  local w = WindowAct[ids.license]
  if w then
    local mode = Config.DailyReferrerActivity and Config.DailyReferrerActivity.Window or 'day'
    if mode=='hour' then
      MySQL.prepare.await([[
        INSERT INTO ref_hour_activity (license, hour_start, seconds_active)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE seconds_active = GREATEST(seconds_active, VALUES(seconds_active))
      ]], { ids.license, w.key, w.seconds_window or 0 })
    else
      MySQL.prepare.await([[
        INSERT INTO ref_daily_activity (license, day_date, seconds_active)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE seconds_active = GREATEST(seconds_active, VALUES(seconds_active))
      ]], { ids.license, w.key, w.seconds_window or 0 })
    end
    WindowAct[ids.license] = nil
  end

  Active[ids.license] = nil
end)

-- =========================
-- Debug helpers
-- =========================
RegisterCommand('ref_reloadtop', function(src)
  if src > 0 and not (Config.Debug and Config.Debug.Enable) then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Debug off.' }); return
  end
  rebuildLeaderboard()
  if src > 0 then TriggerClientEvent('ox_lib:notify', src, { type='success', description='Leaderboard di-refresh.' }) end
end, false)

-- Pakai kode milik player, tandai debug=1
lib.callback.register('tk_referral:debug:createCode', function(src)
  if not (Config.Debug and Config.Debug.Enable) then return false, 'Debug off' end

  local Player = QBCore.Functions.GetPlayer(src)
  if not Player then return false, 'Player not found' end

  local ids = getIdentifiers(src)
  if not ids.license then return false, 'No license' end

  local row = MySQL.single.await('SELECT code FROM referral_codes WHERE license = ? LIMIT 1', { ids.license })
  local code
  if row and row.code then
    MySQL.update.await('UPDATE referral_codes SET is_debug = 1 WHERE license = ?', { ids.license })
    code = row.code
  else
    local alias = (Player.PlayerData.charinfo and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname))
                  or Player.PlayerData.name or ('CID ' .. Player.PlayerData.citizenid)
    code = Utils.generateCode(ids.license, Player.PlayerData.citizenid, (Config.Code and Config.Code.Prefix) or 'TIKUM-', (Config.Code and Config.Code.RandomLength) or 6)
    MySQL.insert.await(
      'INSERT INTO referral_codes (license, citizenid, code, alias, is_debug, created_at) VALUES (?, ?, ?, ?, 1, NOW())',
      { ids.license, Player.PlayerData.citizenid, code, alias }
    )
  end

  return true, code
end)