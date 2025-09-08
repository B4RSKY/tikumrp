Config = {}

Config["SK-UI"] = true -- Set to true if using the most recent version of SK-UI (v1.0)

Config["Backpack"] = {
    owner = true, -- Each backpack item has its own unique inventory (realistic)
    requireItem = true, -- Need the item to have the inv open.    
    itemName = "backpack", -- The item name for the backpack if requireItem is true.
    slots = 20, -- Default amount of slots (used as fallback when bp_slot is not defined)
    maxWeight = 40 -- Default max weight in kg (used as fallback when bp_weight is not defined)
    
    --[[
    NOTE: Individual backpack capacities are now defined in the item definitions using:
    - bp_slot: Number of inventory slots
    - bp_weight: Weight capacity in kilograms
    - backpack: Boolean (true) to identify the item as a backpack
    
    Example:
    ['backpack'] = {
        label = 'Small Backpack',
        weight = 220,
        bp_weight = 40, -- 40kg capacity
        bp_slot = 20,   -- 20 slots
        backpack = true, -- Identifies as backpack
        stack = false,
        close = true,
        description = 'A small backpack for carrying basic items.'
    }
    --]]
}

Config["ArmorPlates"] = {
    MaxPlates = 5,
    ArmorPerPlate = 20,
    VestItem = 'armour', -- Do NOT Change, It is currently hardcoded as "armour" in UI for plate buttons, this will be sort next update!
    PlateItem = "armour_plate"
}

Config["BackpackProp"] = { -- Player wear bag clothe when backpack equipped
    ["Enabled"] = false,
    ["male"] = {
        ["DrawableID"] = 45,
        ["Texture"] = 0
    },
    ["female"] = {
        ["DrawableID"] = 45, -- Non tested for female
        ["Texture"] = 0
    }
}

Config["EnableItemDrops"] = true -- Enables the item drops below, Items not in the array will still be dropped as bag

Config["DefaultDropModel"] = "prop_paper_bag_01" -- Paper bag

Config["ItemDrops"] = { -- item name = prop name will drop that prop on ground.
    WEAPON_PISTOL = `w_pi_pistol`,
    burger = `prop_cs_burger_01`
}

Config["Auto-Use"] = { -- Need to finish armor + parachute auto
    ["Armor"] = true, -- Auto use armor in armor slot?
    ["Parachute"] = true, -- Auto use parachute in parachute slot?
    ["Reload"] = false, -- Auto reload your weapon when it runs out of ammo?
}

-- Update the blacklist to include all backpack types
Config["BackpackBlacklist"] = {
    'backpack',
    'backpack_medium',
    'backpack_large',
    'tactical_backpack'
}

Config["Items"] = {
    ["CustomMetadata"] = {
        'water'
    }
}

-- Update the utility slots to include all backpack types
Config["UtilitySlots"] = { -- Weapons are done automatically.
    {
        'backpack',
        'backpack_medium',
        'backpack_large',
        'tactical_backpack'
    }, -- Backpack Slot
    {'armour'}, -- Armour Slot
    {'phone'}, -- Phone Slot
    {'parachute'}, -- Parachute Slot
}
-- NEW: Theme Configuration System
Config["Themes"] = {
    -- Current theme to use (change this to switch themes)
    current = "purple", -- Options: "default", "dark", "blue", "purple", "red", "green", "custom"
    
    -- Define available themes
    themes = {
        ["default"] = {
            name = "Default Green",
            colors = {
                primary = "#87da21",           -- Main accent color
                primaryRgb = "135, 218, 33",   -- RGB version for rgba usage
                secondary = "#2b2b2b",         -- Secondary backgrounds
                background = "#000000",        -- Main background
                surface = "#1a1a1a",          -- Card/surface backgrounds
                text = "#ffffff",             -- Primary text
                textSecondary = "#c1c2c5",    -- Secondary text
                border = "#ffffff40",         -- Border colors
                success = "#4ade80",          -- Success color
                warning = "#fbbf24",          -- Warning color
                error = "#ef4444",            -- Error color
                common = "#ffffff40",         -- Common rarity
                uncommon = "#23db0b",         -- Uncommon rarity
                rare = "#0796c2",             -- Rare rarity
                epic = "#9c32e4",             -- Epic rarity
                mythic = "#e1e432"            -- Mythic rarity
            }
        },
        
        ["dark"] = {
            name = "Dark Mode",
            colors = {
                primary = "#6366f1",
                primaryRgb = "99, 102, 241",
                secondary = "#1f1f23",
                background = "#09090b",
                surface = "#161618",
                text = "#fafafa",
                textSecondary = "#a1a1aa",
                border = "#27272a",
                success = "#22c55e",
                warning = "#eab308",
                error = "#dc2626",
                common = "#71717a",
                uncommon = "#22c55e",
                rare = "#3b82f6",
                epic = "#a855f7",
                mythic = "#eab308"
            }
        },
        
        ["blue"] = {
            name = "Ocean Blue",
            colors = {
                primary = "#0ea5e9",
                primaryRgb = "14, 165, 233",
                secondary = "#313b4c",
                background = "#020617",
                surface = "#0f172a",
                text = "#f8fafc",
                textSecondary = "#cbd5e1",
                border = "#334155",
                success = "#10b981",
                warning = "#f59e0b",
                error = "#ef4444",
                common = "#64748b",
                uncommon = "#10b981",
                rare = "#3b82f6",
                epic = "#8b5cf6",
                mythic = "#f59e0b"
            }
        },
        
        ["purple"] = {
            name = "Royal Purple",
            colors = {
                primary = "#a855f7",
                primaryRgb = "168, 85, 247",
                secondary = "#2e1065",
                background = "#1e1b4b",
                surface = "#312e81",
                text = "#f3f4f6",
                textSecondary = "#d1d5db",
                border = "#4c1d95",
                success = "#059669",
                warning = "#d97706",
                error = "#dc2626",
                common = "#6b7280",
                uncommon = "#059669",
                rare = "#3b82f6",
                epic = "#a855f7",
                mythic = "#d97706"
            }
        },
        
        ["red"] = {
            name = "Crimson Red",
            colors = {
                primary = "#dc2626",
                primaryRgb = "220, 38, 38",
                secondary = "#7f1d1d",
                background = "#450a0a",
                surface = "#991b1b",
                text = "#fef2f2",
                textSecondary = "#fecaca",
                border = "#b91c1c",
                success = "#16a34a",
                warning = "#ea580c",
                error = "#dc2626",
                common = "#6b7280",
                uncommon = "#16a34a",
                rare = "#2563eb",
                epic = "#9333ea",
                mythic = "#ea580c"
            }
        },
        
        ["green"] = {
            name = "Forest Green",
            colors = {
                primary = "#16a34a",
                primaryRgb = "22, 163, 74",
                secondary = "#14532d",
                background = "#052e16",
                surface = "#166534",
                text = "#f0fdf4",
                textSecondary = "#bbf7d0",
                border = "#22c55e",
                success = "#16a34a",
                warning = "#ea580c",
                error = "#dc2626",
                common = "#6b7280",
                uncommon = "#16a34a",
                rare = "#0ea5e9",
                epic = "#a855f7",
                mythic = "#ea580c"
            }
        },
        
        ["custom"] = {
            name = "Custom Theme",
            colors = {
                -- You can customize these colors to your liking
                primary = "#ff6b35",           -- Orange accent
                primaryRgb = "255, 107, 53",
                secondary = "#2d3748",
                background = "#1a202c",
                surface = "#2d3748",
                text = "#f7fafc",
                textSecondary = "#e2e8f0",
                border = "#4a5568",
                success = "#48bb78",
                warning = "#ed8936",
                error = "#f56565",
                common = "#718096",
                uncommon = "#48bb78",
                rare = "#4299e1",
                epic = "#9f7aea",
                mythic = "#ed8936"
            }
        }
    }
}