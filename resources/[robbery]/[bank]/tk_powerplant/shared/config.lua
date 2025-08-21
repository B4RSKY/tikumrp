Config = {
    --- Compatibility Settings
    Resource = GetCurrentResourceName(),
    Logging = 'qb', -- 'ox_lib' or 'qb' or 'esx'
    Debug = true, -- true | false, enable debug mode
    Lang = 'en', -- Language, choose one of the prefixes from the locales folder
    Framework = 'qbcore', -- 'qbcore', 'esx' or 'qbox', used in modules > utils > server for weathersync

    ThermiteItem = 'thermite',
    MinimumPolice = 0, -- Required amount of cops to be able to hit the powerplant stations

    ThermiteSettings = {
        correctBlocks = 1, -- Number of correct blocks the player needs to click
        incorrectBlocks = 4, -- Number of incorrect blocks after which the game will fail
        timetoShow = 12, -- Time in seconds for which the right blocks will be shown
        timetoLose = 24 -- Maximum time after timetoshow seconds for player to select the right blocks
    },

    Locations = {
        [1] = { coords = vec3(2835.17, 1505.23, 24.85), animation = vec3(2835.14, 1505.48, 24.72), ptfx = vec3(2835.24, 1506.26, 24.72), hit = false }, -- East Power Plant 1
        [2] = { coords = vec3(2811.83, 1501.10, 24.90), animation = vec3(2811.86, 1500.8, 24.72), ptfx = vec3(2811.76, 1501.8, 24.72), hit = false }, -- East Power Plant 2
        [3] = { coords = vec3(2734.54, 1475.55, 45.30), animation = vec3(2734.43, 1475.87, 45.29), ptfx = vec3(2734.42, 1476.87, 45.29), hit = false }, -- East Power Plant 3
        [4] = { coords = vec3(2742.66, 1505.82, 45.30), animation = vec3(2742.52, 1505.82, 45.45), ptfx = vec3(2742.36, 1506.82, 45.45), hit = false }, -- East Power Plant 4
        [5] = { coords = vec3(708.81, 117.01, 81.17), animation = vec3(708.92, 117.24, 81.05), ptfx = vec3(708.92, 118.24, 80.95), hit = false }, -- Powerplant City 1
        [6] = { coords = vec3(670.35, 128.6, 81.25), animation = vec3(670.43, 128.34, 81.05), ptfx = vec3(670.23, 129.39, 80.95), hit = false }, -- Powerplant City 2 
        [7] = { coords = vec3(692.09, 159.97, 81.25), animation = vec3(692.17, 159.94, 81.04), ptfx = vec3(692.17, 160.89, 80.94), hit = false } -- Powerplant City 3
    }
}
