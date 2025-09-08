CreateThread(function()
	while Config.Discord.isEnabled do
        local namanya = GetPlayerName(PlayerId())
        local kantong = GetPlayerServerId(PlayerId())
		local plyrcount = NetworkGetNumConnectedPlayers() or 64
		SetDiscordAppId(Config.Discord.applicationId)
        SetRichPresence('[' ..kantong.. '] '..namanya..' - '..plyrcount..' Players')
        SetDiscordRichPresenceAsset(Config.Discord.iconLarge)
        SetDiscordRichPresenceAssetText(Config.Discord.iconLargeHoverText)
        SetDiscordRichPresenceAssetSmall(Config.Discord.iconSmall)
        SetDiscordRichPresenceAssetSmallText(Config.Discord.iconSmallHoverText)
        SetDiscordRichPresenceAction(0, "Discord", "https://discord.gg/a9SPzgegrp")
		Wait(Config.Discord.updateRate)
	end
end)