Config = {}
Config.AutoRespawn = false          -- true == stores cars in garage on restart | false == doesnt modify car states
Config.VisuallyDamageCars = true   -- true == damage car on spawn | false == no damage on spawn
Config.SharedGarages = false       -- true == take any car from any garage | false == only take car from garage stored in
Config.ClassSystem = false         -- true == restrict vehicles by class | false == any vehicle class in any garage
Config.FuelResource = 'cdn-fuel' -- supports any that has a GetFuel() and SetFuel() export
Config.Warp = true                 -- true == warp player into vehicle | false == vehicle spawns without warping

-- https://docs.fivem.net/natives/?_0x29439776AAA00A62
Config.VehicleClass = {
    all = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 },
    car = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 18, 22 },
    air = { 15, 16 },
    sea = { 14 },
    rig = { 10, 11, 17, 19, 20 }
}

Config.Garages = {
    garasi_a = {
        label = 'Garasi A',
        takeVehicle = vector3(-285.52, -886.33, 31.08),
        zone = {
            shape = { -- Create a polyzone by using '/pzcreate poly', '/pzadd' and '/pzfinish' or '/pzcancel' to cancel it. the newly created polyzone will be in txData/QBCoreFramework_******.base/polyzone_created_zones.txt
                vector2(-284.40274047852, -891.24841308594),
                vector2(-283.17764282227, -885.04949951172),
                vector2(-294.08416748047, -882.70208740234),
                vector2(-295.47579956055, -889.06732177734)
            },
            minZ = 30.019950866699,
            maxZ = 34.019950866699,
            -- VERY IMPORTANT: Make sure the parking zone is high enough - higher than the tallest vehicle and LOW ENOUGH / touches the ground (turn on debug to see)
        },
        spawnPoint = {
            vector4(-285.52, -886.33, 31.08, 168.22),
            vector4(-289.29, -887.11, 31.08, 170.73),
            vector4(-292.95, -885.78, 31.08, 175.08)
        },
        showBlip = true,
        blipName = 'Garasi A',
        blipNumber = 357,
        blipColor = 38,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garasi_b = {
        label = 'Garasi B',
        takeVehicle = vector3(-484.77, -1069.34, 22.59),
        zone = {
            shape = {
                vector2(-486.77798461914, -1065.4161376953),
                vector2(-475.84524536133, -1065.330078125),
                vector2(-475.90774536133, -1070.6335449219),
                vector2(-486.73031616211, -1070.7386474609)
            },
                minZ = 22.589159011841,
                maxZ = 22.589159011841
        },
        spawnPoint = {
            vector4(-484.77, -1069.34, 22.59, 351.08),
            vector4(-481.19, -1068.0, 22.59, 359.88),
            vector4(-477.7, -1068.17, 22.59, 6.38)
        },
        showBlip = true,
        blipName = 'Garasi B',
        blipNumber = 357,
        blipColor = 38,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garasi_c = {
        label = 'Garasi C',
        takeVehicle = vector3(-1795.35, -1172.49, 13.02),
        zone = {
            shape = {
                vector2(-1793.3948974609, -1175.0788574219),
                vector2(-1788.4893798828, -1169.3039550781),
                vector2(-1795.8017578125, -1167.3311767578),
                vector2(-1800.3023681641, -1173.12109375)
            },
                minZ = 22.589159011841,
                maxZ = 22.589159011841
        },
        spawnPoint = {
            vector4(-1795.35, -1172.49, 13.02, 262.62),
            vector4(-1794.18, -1169.46, 13.02, 251.38)
        },
        showBlip = true,
        blipName = 'Garasi C',
        blipNumber = 357,
        blipColor = 38,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garasi_d = {
        label = 'Garasi D',
        takeVehicle = vector3(-894.23, -2061.47, 9.3),
        zone = {
            shape = {
                vector2(-894.79321289062, -2058.4541015625),
                vector2(-902.32751464844, -2065.8205566406),
                vector2(-898.58984375, -2069.7419433594),
                vector2(-891.03607177734, -2062.109375)
            },
            minZ = 9.2994222640991,
            maxZ = 9.2994222640991
        },
        spawnPoint = {
            vector4(-894.23, -2061.47, 9.3, 44.5),
            vector4(-896.74, -2064.2, 9.3, 45.34),
            vector4(-899.06, -2066.89, 9.3, 51.88)
        },
        showBlip = true,
        blipName = 'Garasi D',
        blipNumber = 357,
        blipColor = 38,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garasi_e = {
        label = 'Garasi E',
        takeVehicle = vector3(-413.75, 1202.32, 325.64),
        zone = {
            shape = {
                vector2(-411.49542236328, 1197.4055175781),
                vector2(-418.44305419922, 1199.3898925781),
                vector2(-416.19934082031, 1207.2524414062),
                vector2(-409.32995605469, 1205.3203125)
            },
            minZ = 325.64172363281,
            maxZ = 325.66644287109
        },
        spawnPoint = {
            vector4(-413.75, 1202.32, 325.64, 166.19)
        },
        showBlip = true,
        blipName = 'Garasi E',
        blipNumber = 357,
        blipColor = 38,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    asuransi_a = {
        label = 'Asuransi',
        takeVehicle = vector3(256.69, 2602.95, 44.89),
        zone = {
            shape = {
                vector2(260.50607299805, 2598.4812011719),
                vector2(258.48648071289, 2608.1750488281),
                vector2(250.26028442383, 2606.5339355469),
                vector2(251.91105651855, 2596.8435058594)
            },
            minZ = 42.883563995361,
            maxZ = 48.955417633057
        },
        spawnPoint = {
            vector4(256.69, 2602.95, 44.89, 11.86)
        },
        showBlip = true,
        blipName = 'Asuransi',
        blipNumber = 67,
        blipColor = 47,
        type = 'depot',
        category = Config.VehicleClass['car']
    },
}
