Config = {}

-- TEST: 60 detik; PROD: 3600 (60 menit)
Config.RequirementSeconds = 60
Config.Grace = { Enable = false, Minutes = 15, MaxActiveSeconds = 300 }
Config.Code = { Prefix = 'TIKUM-', RandomLength = 6 }

Config.AfkDetect = {
  Enable = true,
  MaxIdleSeconds = 900,
  MinMoveDistance = 1.0,
  MinSpeed = 0.40,
  HeartbeatSecs = 2,
  TallyTickSecs = 5
}

Config.Persistence = {
  ReferralFlushSecs = 30,
  WindowFlushSecs   = 60
}

Config.Leaderboard = {
  TopN = 10,
  InGameRefreshMinutes = 60,
  DiscordRefreshHours  = 2,
  FallbackToLifetimeIfEmpty = true
}

Config.DailyReferrerActivity = {
  Enable = true,
  Window = 'day',
  Minutes = 1,         -- TEST 1; PROD 60
  Policy = 'DECAY',
  DecayPerWindow = 1,  -- dipakai saat 'hour'
  DecayPerDay = 1,     -- dipakai saat 'day'
  Floor = 1,
  TimezoneOffsetMinutes = 420
}

Config.Validation = {
  UniquePer = { license = true, steam = true, discord = true, ip = true },
  MaxRedeemsPerIPPerDay = 6,
  UniqueIPWindowSeconds = 300,   -- <<< 5 menit
  UniqueIPWindowDays    = 0,
  UniquenessMode = 'ANY',
  MaxConcurrentActiveByReferrer = 10
}

Config.Rewards = {
  ReferredOnRedeem   = { money = 0, items = {} },
  ReferredOnComplete = { money = 5000, items = { bread=3, water=3 } },

  ReferrerMilestones = {
    [1]  = { money = 10000 },
    [2]  = { items = { phone = 1 } },
    [5]  = { money = 25000, items = { repairkit = 5 } },
    [10] = { money = 50000, items = { radio = 1 } },
  },

  MoneyAccount = 'cash',
  LockOnRedeemUntilComplete = true
}

Config.Webhook = { Enable = true, Url = 'https://discord.com/api/webhooks/1345955044276830239/7cakaXqTZAv1ZSO37S28ieEKgDePbQ0ceiyqQKOujxEFIHjd1Pv_MY88ciTCOYyTDf7m' }

Config.Debug = {
  Enable = false,
  AfkVerbose = false,
  ExcludeDebugFromLeaderboard = true,
  ExcludeDebugFromMilestones  = false,
  AllowSelfRedeem = false
}