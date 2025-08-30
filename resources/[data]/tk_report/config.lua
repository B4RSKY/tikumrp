Config = {}

Config.Debug = true
Config.DebugPrint = false

-- Language
Config.Language = { -- en, es
    Default = 'en',
}

-- Permissions
Config.Permissions = {
    -- Admin
    'reportmenu.admin.view',
    'reportmenu.admin.manage',
    'reportmenu.admin.delete',
    -- Mod
    'reportmenu.mod.view',
    'reportmenu.mod.manage',
}

-- Cooldowns
Config.Cooldowns = {
    Chat = 5000,    -- 5 seconds
    Report = 10000, -- 10 seconds
    Theme = 10000   -- 10 seconds
}

-- Discord Webhook
Config.Discord = {
    Enabled = true, -- Set to true to enable Discord integration
    Webhook = 'https://discord.com/api/webhooks/1410901543984566342/EtKvJ59araKUknYbX76z398OcpIMshPXeyNKfrpDVZgLgTvZzLFBgTIOCMQgDgpmBn1m', -- Replace with your actual webhook URL
    ImageUrl = 'https://files.fivemerr.com/images/a437452f-5f0d-4550-aa83-2ac7e4aaa394.png', 
    ReportEmbedColor = 16711680, -- Red
    CreateEmebedColor = 65280, -- Green
}

-- FiveManage API
Config.FiveManage = {
    ApiKey = "YOUR_API_KEY",  -- Replace with your actual API key (https://fivemanage.com/)
    DeleteMedia = true,       -- Delete media files after report deletion
}