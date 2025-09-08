Config = {}

Config.RequirementSeconds = 120                -- 3600
Config.Grace = { Enable = true, Minutes = 15, MaxActiveSeconds = 300 }

Config.DailyReferrerActivity = {
  Enable = true,
  Window = 'hour',         -- 'day' | 'hour'
  Minutes = 1,             -- syarat aktif per window (TEST: 1 menit biar cepat)
  Policy = 'DECAY',        -- atau 'HIDE' kalau tampil/hilang
  DecayPerDay = 1,         -- dipakai jika Window='day'
  DecayPerWindow = 1,      -- dipakai jika Window='hour' (set 1 point per jam)
  Floor = 0,
  TimezoneOffsetMinutes = 420  -- WIB
}

Config.AfkDetect = {
    Enable = true,
    MaxIdleSeconds = 15,      -- utk test; production  >= 45-60
    MinMoveDistance = 0.30,   -- kecilin biar gerakan kecil kebaca
    MinSpeed = 0.40,          -- m/s; kalau speed >= ini dianggap aktif
    HeartbeatSecs = 2,        -- kirim posisi lebih sering saat test
    TallyTickSecs = 5         -- server akumulasi tiap 5 detik saat test
}

-- === Leaderboard & Webhook ===
Config.Leaderboard = {
    Mode = 'lifetime',
    TopN = 10,
    InGameRefreshMinutes = 1, -- rebuild cache in-game tiap 1 jam
    DiscordRefreshHours = 1   -- kirim embed ke Discord tiap 12 jam
}
Config.Webhook = {
    Enable = true,
    Url = 'https://discord.com/api/webhooks/1345955044276830239/7cakaXqTZAv1ZSO37S28ieEKgDePbQ0ceiyqQKOujxEFIHjd1Pv_MY88ciTCOYyTDf7m' -- ganti punyamu
}

Config.Validation = {
    UniquePer = { license = true, steam = true, discord = true, ip = true },
    UniquenessMode = 'ANY',         -- ANY = tolak kalau salah satu ID sudah pernah redeem
    UniqueIPWindowDays = 7,         -- “masa karantina IP” (0 = nonaktif)
    MaxRedeemsPerIPPerDay = 2,
    MaxConcurrentActiveByReferrer = 10, -- referral belum complete per referrer
    PlaytimeGate = { Enabled = false, MaxSeconds = 0 } -- semua player bisa redeem tanpa gate
}

Config.Rewards = {
    -- Hadiah untuk pemain yang REDEEM (opsional):
    ReferredOnRedeem = { money = 0, items = {} },  -- contoh: { money = 1000, items = { water = 1 } }

    -- Hadiah untuk pemain yang COMPLETE (wajib):
    ReferredOnComplete = { money = 5000, items = { bread = 3, water = 3 } },

    -- Milestone untuk REFERRER (berdasar jumlah referral COMPLETED)
    ReferrerMilestones = {
        [1]  = { money = 10000 },
        [2]  = { items = { phone = 1 } },
        [5]  = { money = 25000, items = { repairkit = 5 } },
        [10] = { money = 50000, items = { radio = 1 } },
        [20] = { money = 120000, items = { armor = 3 } },
        [50] = { money = 350000, items = { weapon_pistol = 1, pistol_ammo = 50 } }
    },

    MoneyAccount = 'cash' -- 'cash' atau 'bank'
}

-- === UI ===
Config.UI = {
    Theme = 'purple-black',
    UseNUILeaderboard = false
}

Config.Code = {
  Prefix = 'TIKUM-',
  RandomLength = 6
}

Config.Debug = {
    Enable = true,                 -- aktifkan tools debug
    AllowAnyPlayer = true,         -- kalau false, cek ACE / group (silakan modif sendiri)
    ExcludeDebugFromLeaderboard = false,
    AfkVerbose = true         -- << nyalakan log AFK detail
}