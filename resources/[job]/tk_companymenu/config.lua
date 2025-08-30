Config = {}

Config.BankingSystem = "renewed-banking"
Config.TargetSystem = "ox_target"
Config.EnableApplicationSystem = false

Config.Locations = {
    ["police"] = {
        label = "POLDA TIKUM",
        logoImage = "police.png",
        locations = {
            {
                coords = vector3(94.74, -405.49, 47.32), -- Main Police Station
                width = 1.0,
                length = 1.0,
                heading = 0,
                minZ = 30.0,
                maxZ = 31.0,
            }
        }
    },
    ["ambulance"] = {
        label = "Rumah Sakit",
        logoImage = "ems.png",
        locations = {
            {
                coords = vector3(-490.03, -980.43, 34.3), -- Main Hospital
                width = 1.0,
                length = 1.0,
                heading = 0,
                minZ = 43.0,
                maxZ = 44.0,
            }
        }
    },
    ["mechanic"] = {
        label = "TIKUM SPEED",
        logoImage = "mechanic.png",
        locations = {
            {
                coords = vector3(-921.31, -2044.38, 15.28), -- Mechanic Shop
                width = 1.0,
                length = 1.0,
                heading = 0,
                minZ = 25.0,
                maxZ = 26.0,
            }
        }
    }
}

Config.ApplicationPoints = {
    ["police"] = {
        coords = vector3(441.53604, -980.1955, 30.795989),  -- Near the police station
        width = 1.0,
        length = 1.0,
        heading = 0,
        minZ = 30.0,
        maxZ = 31.0,
        label = "Police Application"
    },
    ["ambulance"] = {
        coords = vector3(310.45, -597.47, 43.28),  -- Near the hospital
        width = 1.0,
        length = 1.0,
        heading = 0,
        minZ = 43.0,
        maxZ = 44.0,
        label = "EMS Application"
    },
    ["mechanic"] = {
        coords = vector3(835.92, -912.54, 25.25),  -- Near the mechanic shop
        width = 1.0,
        length = 1.0,
        heading = 0,
        minZ = 25.0,
        maxZ = 26.0,
        label = "Mechanic Application"
    },
}

Config.ApplicationQuestions = {
    ["police"] = {
        {
            question = "Why do you want to join the Police Department?",
            type = "text",
            required = true,
            min = 1,
            max = 1024
        },
        {
            question = "Do you have any previous law enforcement experience?",
            type = "select",
            options = {"Yes", "No"},
            required = true
        },
        {
            question = "How many years of experience do you have?",
            type = "number",
            required = false,
            min = 0,
            max = 50
        },
        {
            question = "How would you handle a high-stress situation?",
            type = "text",
            required = true,
            min = 1,
            max = 1024
        }
    }
}

-- Default settings
Config.DefaultSettings = {
    darkMode = true,
    showAnimations = true,
    compactView = false,
    notificationSound = "default",
    themeColor = "purple",
    refreshInterval = 60,
    showPlaytime = true,
    showLocation = false
}
