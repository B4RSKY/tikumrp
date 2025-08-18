AddEventHandler('onClientResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	print('Starting script initialization')

	-- Some people modify pma-voice and mess up the resource Kvp, which means that if someone
	-- joins another server that has pma-voice, it will error out, this will catch and fix the kvp.
	local success = pcall(function()
		local micClicksKvp = GetResourceKvpString('pma-voice_enableMicClicks')
		if not micClicksKvp then
			SetResourceKvp('pma-voice_enableMicClicks', "true")
			micClicks = true
		else
			if micClicksKvp ~= 'true' and micClicksKvp ~= 'false' then
				error('Invalid Kvp, throwing error for automatic fix')
			end
			micClicks = micClicksKvp == "true"
		end
	end)

	if not success then
		logger.warn(
			'Failed to load resource Kvp, likely was inappropriately modified by another server, resetting the Kvp.')
		SetResourceKvp('pma-voice_enableMicClicks', "true")
		micClicks = true
	end
	sendUIMessage({
		uiEnabled = GetConvarInt("voice_enableUi", 1) == 1,
		voiceModes = json.encode(Cfg.voiceModes),
		voiceMode = mode - 1
	})

	local radioChannel = LocalPlayer.state.radioChannel or 0
	local callChannel = LocalPlayer.state.callChannel or 0

	-- Reinitialize channels if they're set.
	if radioChannel ~= 0 then
		setRadioChannel(radioChannel)
	end

	if callChannel ~= 0 then
		setCallChannel(callChannel)
	end
	if not LocalPlayer.state.disableRadio then
		LocalPlayer.state:set("disableRadio", 0, true)
	end

	print('Script initialization finished.')
end)

local color = {
	[1] = {r=143, g=255, b=75},
	[2] = {r=75, g=203, b=255},
	[3] = {r=255, g=75, b=149}
}
local alpha = 150
local delay = 0
local delayTime = 1000
local seccess = nil

local function voiceDistance(mode)
    local distance = Cfg.voiceModes[mode][1] * 2
    local r,g,b,a = color[mode].r, color[mode].g, color[mode].b, alpha
    seccess = false
    delay = delayTime
    while not seccess do
        DrawMarker(1, GetEntityCoords(PlayerPedId())+vector3(0,0,0), 0.0,0.0,0.0, 0.0,0.0,0.0, distance,distance,0.125, r,g,b,math.floor((delay*a)/delayTime), false,true,2,nil,nil,false)
        DrawMarker(1, GetEntityCoords(PlayerPedId())+vector3(0,0,0.025), 0.0,0.0,0.0, 0.0,0.0,0.0, distance,distance,-0.125, r,g,b,math.floor((delay*a)/delayTime), false,true,2,nil,nil,false)
        Wait(0)
        delay = delay-10
        if delay <= 0 then
          seccess = true
        end
    end
end

AddEventHandler('pma-voice:setTalkingMode', function(mode)
    seccess = true
    Wait(10)
    voiceDistance(mode)
end)