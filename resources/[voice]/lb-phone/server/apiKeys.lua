-- Webhook for instapic posts, recommended to be a public channel
INSTAPIC_WEBHOOK = "https://discord.com/api/webhooks/1408116780689391867/iSln_SJ4gEWD43hnK8shZ1xYBVQd5AKJNA1iCrFnha6PbYcZS-NE7NGjbiGTThvXAJvI"
-- Webhook for birdy posts, recommended to be a public channel
BIRDY_WEBHOOK = "https://discord.com/api/webhooks/1408116640037601350/P8CU3opgDbwLfxnB1CwCm0sXvgku70Syz_DqOX3TEKGxKjgd0IcoJYjlSrhOl9ljMgoZ"

-- Discord webhook or API key for server logs
-- We recommend https://fivemanage.com/ for logs. Use code "LBLOGS" for 20% off the Logs Pro plan
LOGS = {
    Default = "https://discord.com/api/webhooks/1408119382038548590/KG-piVKLa2mm74lVkH5nwLu77EqeTHPwbrpDD-yEmM0h60iZEo3gRtg4HqbrEX7m3ott", -- set to false to disable
    Calls = "https://discord.com/api/webhooks/",
    Messages = "https://discord.com/api/webhooks/",
    InstaPic = "https://discord.com/api/webhooks/",
    Birdy = "https://discord.com/api/webhooks/",
    YellowPages = "https://discord.com/api/webhooks/",
    Marketplace = "https://discord.com/api/webhooks/",
    Mail = "https://discord.com/api/webhooks/",
    Wallet = "https://discord.com/api/webhooks/",
    DarkChat = "https://discord.com/api/webhooks/",
    Services = "https://discord.com/api/webhooks/",
    Crypto = "https://discord.com/api/webhooks/",
    Trendy = "https://discord.com/api/webhooks/",
    Uploads = "https://discord.com/api/webhooks/" -- all camera uploads will go here
}

DISCORD_TOKEN = nil -- you can set a discord bot token here to get the players discord avatar for logs

-- Set your API keys for uploading media here.
-- Please note that the API key needs to match the correct upload method defined in Config.UploadMethod.
-- The default upload method is Fivemanage
-- You can get your API keys from https://fivemanage.com/
-- Use code LBPHONE10 for 10% off on Fivemanage
-- A video tutorial for how to set up Fivemanage can be found here: https://www.youtube.com/watch?v=y3bCaHS6Moc
API_KEYS = {
    Video = "qqAg5N0tGJFy715sFCQr00XBqxZGqD0r",
    Image = "60rQrxPvI4qaScE59quk15HS7eztjkc4",
    Audio = "XfL0jiTVX6OliOXRVJrFJJNpBGZpdD57",
}

-- Here you can set your credentials for Config.DynamicWebRTC
-- This is needed if video calls or InstaPic live streams are not working
-- You can get your credentials from https://dash.cloudflare.com/?to=/:account/realtime/turn/overview
WEBRTC = {
    TokenID = nil,
    APIToken = nil,
}
