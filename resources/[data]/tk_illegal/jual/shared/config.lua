local Config = {}

Config.MaxPedsPerZone = 7
Config.SpawnBurstDelay = 50
Config.PedSalesCap = 1
Config.TransactionCooldown = 2.0
Config.AllowedGangs = { 'ballas', 'vagos', 'badside1' }
Config.Items = {
    micin_turbo  = { label = 'Micin Turbo',  priceMin = 120, priceMax = 180, maxPerTransaction = 50 },
    kopi_hyper   = { label = 'Kopi Hyper',   priceMin = 300, priceMax = 380, maxPerTransaction = 50 },
}

Config.RequiredAmount = 1
Config.Zones = {
    {
        id = 'grove_market',
        label = 'Grove St. Fence',
        coords = vector3(1472.52, 6364.47, 23.63),
        radius = 40.0,
        npcModels = { `g_m_y_famdnf_01`, `g_m_y_ballaorig_01`, `a_m_m_eastsa_01` },
        wander = { enabled = true, speed = 1.0, retask = { min = 8000, max = 14000 }, leashMargin = 5.0 },
        sellItem = 'micin_turbo',
        maxPeds = 7,
        salesCap = 1,
        dispatch = { baseChance = 18 },
    },
    {
        id = 'docks_fence',
        label = 'Docks Buyer',
        coords = vec3(1205.57, -3253.62, 5.0),
        radius = 45.0,
        npcModels = { `s_m_y_dockwork_01`, `s_m_m_dockwork_01` },
        wander = { enabled = true, speed = 1.0, retask = { min = 9000, max = 16000 }, leashMargin = 6.0 },
        sellItem = 'kopi_hyper',
        maxPeds = 5,
        salesCap = 2,
        dispatch = { baseChance = 22 },
    },
}

Config.SpawnOffset = { min = 2.0, max = 12.0 }
Config.GiveAnimTime = 1.4
Config.Dispatch = {
    enabled = true,
    baseChance = 20,
    nightFactor = 0.6,
}

-- pengaruh harga & chance dispatch
Config.Heat = {
    increasePerSale = 1.0,      -- tiap transaksi, heat zona bertambah sekian
    decayPerMinute  = 0.5,      -- tiap menit, heat berkurang sekian
    maxPriceDiscount = 0.30,    -- diskon maksimal dari heat (30%)
    priceDiscountPerHeat = 0.02,-- diskon per 1 heat (2%)
    dispatchChancePerHeat = 1.5,-- tambahan chance per 1 heat (1.5%)
}

-- Penyesuaian harga berdasar jam server (24h)
-- Malam (20-05) lebih mahal sedikit; siang (12-17) sedikit turun
Config.Pricing = {
    nightHours = {20, 21, 22, 23, 0, 1, 2, 3, 4, 5},
    nightBonus = 0.10,    -- +10% harga
    middayHours = {12, 13, 14, 15, 16, 17},
    middayPenalty = 0.05, -- -5% harga
}

if IsDuplicityVersion() then
    ServerConfig = Config
else
    ClientConfig = Config
end