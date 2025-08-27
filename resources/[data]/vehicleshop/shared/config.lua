lib.locale()
Config = {}

Config.EnableDebug = false
Config.PositioMenu = "top-right"

Config.TestDrive = true
Config.TestDriveTime = 60 --seconds
Config.MarkerDistance = 2.0
Config.RemoveMoneyCompany = true

Config.Shops = {
    cardealer = {
        -- Blip
        title = 'Dealer Kendaraan',
        color = 0,
        id = 820,
        scale = 0.5,
        coords = vector3(-52.2535, -1095.64, 26.422),
        -- Other
        requiredJob = false,
        jobName = 'cardealer',
        gradeBoss = 'boss',
        bossMenu = vector3(-31.0925, -1106.57, 26.422),
        actionjob = vector3(-56.5321, -1099.30, 26.422),
        showcase = vector3(-56.86, -1097.1, 26.42),
        spawnShowCase = vector4(-47.9474, -1096.73, 26.422, 42.292),
        spawnVehicleBuy = vector3(-13.13, -1085.24, 26.68),
        camCoords = vector3(-52.0340, -1092.87, 26.422),
        TestDriveCoords = vector3(-889.877, -3205.54, 13.944)
    },
    -- police = {
    --     -- Blip
    --     title = 'Police Dealership',
    --     color = 38,
    --     id = 227,
    --     scale = 0.8,
    --     coords = vector3(418.4895, -1021.34, 29.030),
    --     -- Other
    --     requiredJob = true,
    --     jobName = 'police',
    --     gradeBoss = 'boss',
    --     bossMenu = vector3(-43.7882, -1116.28, 26.427),
    --     actionjob = vector3(417.5868, -1004.78, 29.233),
    --     showcase = vector3(421.2276, -1011.13, 29.129),
    --     spawnShowCase = vector4(423.9533, -1022.07, 28.929, 92.051),
    --     spawnVehicleBuy = vector3(-58.1253, -1116.52, 26.434),
    --     camCoords = vector3(414.4416, -1021.23, 29.199),
    --     TestDriveCoords = vector3(-889.877, -3205.54, 13.944)
    -- },
    -- boat = {
    --     -- Blip
    --     title = 'Boat Dealership',
    --     color = 2,
    --     id = 427,
    --     scale = 0.8,
    --     coords = vector3(-754.725, -1504.79, 5.0005),
    --     -- Other
    --     requiredJob = false,
    --     jobName = '',
    --     gradeBoss = '',
    --     bossMenu = vector3(0, 0, 0),
    --     actionjob = vector3(0, 0, 0),
    --     showcase = vector3(-755.026, -1507.16, 5.0069),
    --     spawnShowCase = vector4(-800.174, -1503.35, -0.474, 113.62),
    --     spawnVehicleBuy = vector3(-58.1253, -1116.52, 26.434),
    --     camCoords = vector3(-779.257, -1496.29, 1.7786),
    --     TestDriveCoords = vector3(-832.4774, -1532.5023, -0.4745)
    -- },
    -- plane = {
    --     -- Blip
    --     title = 'Plane Dealership',
    --     color = 30,
    --     id = 423,
    --     scale = 0.8,
    --     coords = vector3(-1013.82, -3022.10, 13.945),
    --     -- Other
    --     requiredJob = false,
    --     jobName = '',
    --     gradeBoss = '',
    --     bossMenu = vector3(0, 0, 0),
    --     actionjob = vector3(0, 0, 0),
    --     showcase = vector3(-1012.82, -3022.10, 13.945),
    --     spawnShowCase = vector4(-977.132, -2995.10, 13.944, 60.736),
    --     spawnVehicleBuy = vector3(-58.1253, -1116.52, 26.434),
    --     camCoords = vector3(-996.989, -2985.89, 13.945),
    --     TestDriveCoords = vector3(-889.877, -3205.54, 13.944)
    -- },
}

Config.Categories = {
    cardealer = {
        { label = 'Compacts',       name = 'compacts' },
        -- { label = 'Sendas',         name = 'sendas' },
        { label = 'SUVs',           name = 'suvs' },
        -- { label = 'Coupes',         name = 'coupes' },
        { label = 'Muscle',         name = 'muscle' },
        { label = 'Sports Classic', name = 'sportsclassic' },
        { label = 'Sports',         name = 'sports' },
        { label = 'Super',          name = 'super' },
        { label = 'Motorcycles',    name = 'motorcycles' },
        { label = 'Off-Road',       name = 'offroad' },
        { label = 'Vans',           name = 'vans' },
    },
    -- police = {
    --     { label = "Armored",    name = "armored" },
    --     { label = "Car",        name = "car" },
    --     { label = "Motorcycle", name = "motorcycle" },
    -- },
    -- boat = {
    --     { label = "Luxury",  name = "luxury" },
    --     { label = "Utility", name = "utility" },
    -- },
    -- plane = {
    --     { label = "Luxury",  name = "luxury" },
    --     { label = "Utility", name = "utility" },
    -- }
}

Config.Vehicles = {
    -- Vehice Name                Vehicle Model          Vehicle Category            Vehicle Price          Dealership
    -- Dealer Biasa
    -- Motor
    { name = "Faggio",            model = "faggio",      category = "motorcycles",   price = 110000,        dealership = "cardealer" },
    { name = "Manchez",           model = "manchez",     category = "motorcycles",   price = 110000,        dealership = "cardealer" },
    { name = "Sanchez 2",         model = "sanchez2",    category = "motorcycles",   price = 110000,        dealership = "cardealer" },
    { name = "Cliffhanger",       model = "cliffhanger", category = "motorcycles",   price = 110000,        dealership = "cardealer" },
    { name = "Daemon",            model = "daemon",      category = "motorcycles",   price = 150000,        dealership = "cardealer" },
    { name = "Daemon 2",          model = "daemon2",     category = "motorcycles",   price = 160000,        dealership = "cardealer" },
    { name = "Gargoyle",          model = "gargoyle",    category = "motorcycles",   price = 170000,        dealership = "cardealer" },
    { name = "Sanchez",           model = "sanchez",     category = "motorcycles",   price = 170000,        dealership = "cardealer" },
    { name = "Faggio 2",          model = "faggio2",     category = "motorcycles",   price = 170000,        dealership = "cardealer" },
    { name = "Faggio 3",          model = "faggio3",     category = "motorcycles",   price = 1750000,       dealership = "cardealer" },
    { name = "BF 400",            model = "bf400",       category = "motorcycles",   price = 1800000,       dealership = "cardealer" },
    { name = "Avarus",            model = "avarus",      category = "motorcycles",   price = 267500,        dealership = "cardealer" },
    { name = "Wolfsbane",         model = "wolfsbane",   category = "motorcycles",   price = 280000,        dealership = "cardealer" },
    { name = "Bagger",            model = "bagger",      category = "motorcycles",   price = 306500,        dealership = "cardealer" },
    { name = "Esskey",            model = "esskey",      category = "motorcycles",   price = 315250,        dealership = "cardealer" },
    { name = "Sovereign",         model = "sovereign",   category = "motorcycles",   price = 350000,        dealership = "cardealer" },
    { name = "Bati",              model = "bati",        category = "motorcycles",   price = 376500,        dealership = "cardealer" },
    { name = "Defiler",           model = "defiler",     category = "motorcycles",   price = 389000,        dealership = "cardealer" },
    { name = "Akuma",             model = "akuma",       category = "motorcycles",   price = 397500,        dealership = "cardealer" },
    { name = "Double",            model = "double",      category = "motorcycles",   price = 425000,        dealership = "cardealer" },
    { name = "CarbonRS",          model = "carbonrs",    category = "motorcycles",   price = 555000,        dealership = "cardealer" },
    { name = "Shotaro",           model = "shotaro",     category = "motorcycles",   price = 848900,        dealership = "cardealer" },
    
    --Compact
    { name = "Panto",             model = "panto",       category = "compacts",      price = 795000,        dealership = "cardealer" },
    { name = "Brioso",            model = "brioso",      category = "compacts",      price = 1072500,       dealership = "cardealer" },

    -- Muscle
    { name = "Buccaneer 2",       model = "buccaneer2",  category = "muscle",        price = 530250,        dealership = "cardealer" },
    { name = "Chino 2",           model = "chino2",      category = "muscle",        price = 762500,        dealership = "cardealer" },
    { name = "Faction",           model = "faction",     category = "muscle",        price = 630000,        dealership = "cardealer" },
    { name = "Hustler",           model = "hustler",     category = "muscle",        price = 3225000,       dealership = "cardealer" },

    -- Off Road
    { name = "Blazer",            model = "blazer",      category = "offroad",        price = 470500,       dealership = "cardealer" },
    { name = "Bfinjection",       model = "bfinjection", category = "offroad",        price = 827000,       dealership = "cardealer" },
    { name = "Bifta",             model = "bifta",       category = "offroad",        price = 987900,       dealership = "cardealer" },
    { name = "Rebel 2",           model = "rebel2",      category = "offroad",        price = 1060500,      dealership = "cardealer" },
    { name = "Brawler",           model = "brawler",     category = "offroad",        price = 1060500,      dealership = "cardealer" },
    { name = "Guardian",          model = "guardian",    category = "offroad",        price = 1325000,      dealership = "cardealer" },

    --Suvs
    { name = "Mesa 3",            model = "mesa3",       category = "suvs",           price = 1602500,      dealership = "cardealer" },

    --Sports
    { name = "Buffalo",           model = "buffalo",     category = "sports",         price = 1113750,      dealership = "cardealer" },
    { name = "Alpha",             model = "alpha",       category = "sports",         price = 1115000,      dealership = "cardealer" },
    { name = "Banshee",           model = "banshee",     category = "sports",         price = 1195000,      dealership = "cardealer" },
    { name = "Sultan 3",          model = "sultan3",     category = "sports",         price = 1750000,      dealership = "cardealer" },
    { name = "Tampa 2",           model = "tampa2",      category = "sports",         price = 2012500,      dealership = "cardealer" },
    { name = "Comet 5",           model = "comet5",      category = "sports",         price = 2050000,      dealership = "cardealer" },
    { name = "Neon",              model = "neon",        category = "sports",         price = 5730000,      dealership = "cardealer" },

    --super
    { name = "Sultan RS",         model = "sultanrs",    category = "super",          price = 2183250,      dealership = "cardealer" },

    --sport klasik
    { name = "Manana",            model = "manana",      category = "sportsclassic",  price = 1104000,      dealership = "cardealer" },
    { name = "Casco",             model = "casco",       category = "sportsclassic",  price = 1720000,      dealership = "cardealer" },
    { name = "Feltzer 3",         model = "feltzer3",    category = "sportsclassic",  price = 1970750,      dealership = "cardealer" },
    { name = "Mamba",             model = "mamba",       category = "sportsclassic",  price = 2671000,      dealership = "cardealer" },

    --Vans
    { name = "Minivan",           model = "minivan",     category = "vans",           price = 1042000,      dealership = "cardealer" },
    { name = "Burrito 3",         model = "burrito3",    category = "vans",           price = 1270000,      dealership = "cardealer" },
    { name = "Rumpo",             model = "rumpo",       category = "vans",           price = 1503000,      dealership = "cardealer" },
    { name = "Gburrito 2",        model = "gburrito2",   category = "vans",           price = 1860250,      dealership = "cardealer" },

    -- Police Armored
    { name = "riot",              model = "Riot",        category = "armored",       price = 1000, dealership = "police" },
    { name = "riot2",             model = "Riot2",       category = "armored",       price = 1000, dealership = "police" },

    -- Police Car
    { name = "Police",            model = "police",      category = "car",           price = 1000, dealership = "police" },
    { name = "Police 2",          model = "police2",     category = "car",           price = 1000, dealership = "police" },
    { name = "Police 3",          model = "police3",     category = "car",           price = 1000, dealership = "police" },

    --Police Motorcycle
    { name = "Police Motorcycle", model = "policeb",     category = "motorcycle",    price = 1000, dealership = "police" },

    --Boat Luxury
    { name = "Marquis",           model = "marquis",     category = "luxury",        price = 1000, dealership = "boat" },
    { name = "Toro",              model = "toro",        category = "luxury",        price = 1000, dealership = "boat" },

    --Boat Utility
    { name = "Dinghy2",           model = "dinghy2",     category = "utility",       price = 1000, dealership = "boat" },
    { name = "Squalo",            model = "squalo",      category = "utility",       price = 1000, dealership = "boat" },

    --Plane Luxury
    { name = "Luxor",             model = "luxor",       category = "luxury",        price = 1000, dealership = "plane" },
    { name = "Luxor2",            model = "luxor2",      category = "luxury",        price = 1000, dealership = "plane" },

    --Plane Utility
    { name = "Mammatus",          model = "mammatus",    category = "utility",       price = 1000, dealership = "plane" },
    { name = "Cuban800",          model = "cuban800",    category = "utility",       price = 1000, dealership = "plane" },
}
