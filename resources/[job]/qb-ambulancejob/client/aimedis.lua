local QBCore = exports["qb-core"]:GetCoreObject()

local spam = true
local sibuk = false

local maleScene = 'MP_INT_MCS_18_A1'
local femaleScene = 'MP_INT_MCS_18_A2'

local function Finish()
    local tripped = false
    repeat
        Wait(0)
        if (GetCutsceneTotalDuration() - GetCutsceneTime() <= 250) then
        DoScreenFadeOut(250)
        tripped = true
        end
    until not IsCutscenePlaying()
    if (not tripped) then
        DoScreenFadeOut(100)
        Wait(150)

    end
    return
end

local function CreateCutscene(coords)
    StartCutsceneAtCoords(coords, 0)
    DoScreenFadeIn(250)
end

local function PlayCutscene(cut, coords)
    while not HasThisCutsceneLoaded(cut) do
        RequestCutsceneWithPlaybackList(cut, 29, 8)
        Wait(0)
    end
    CreateCutscene(coords)
    Finish()
    RemoveCutscene()
    DoScreenFadeIn(500)
	TriggerEvent('hospital:client:Revive')
end

local function scene()
	SetCutsceneTriggerArea(0.0, 0.0, 0.0, 0.0, 121.6249, 0.0);
    local x = AddNavmeshBlockingObject(-1314.997, -1721.084, 1.1493, 100.0, 100.0, 100.0, 0.0, false, 7)
    SetPedNonCreationArea(-1324.736, -1756.909, -10.0, -1299.695, -1688.181, 10.0)
    SetOverrideWeather('CLEARING')
    SetTransitionTimecycleModifier("Kifflom", 1.0)
    NetworkOverrideClockTime(18, 0, 0)
    N_0xfb680d403909dc70(1, PlayerId() + 32)
    SetRainLevel(0.0)
    PlayCutscene(maleScene, vector3(-1314.997, -1721.084, 1.1493))
    ClearTimecycleModifier()
    ClearPedNonCreationArea()
    RemoveNavmeshBlockingObject(x)
end

RegisterCommand('aimedis', function()
	if not sibuk then
		sibuk = true
		if (QBCore.Functions.GetPlayerData().metadata["isdead"]) or (QBCore.Functions.GetPlayerData().metadata["inlaststand"]) and spam then
			if QBCore.Functions.GetJobCount('ambulance') > Config.Doctor then
				QBCore.Functions.Notify('EMS', 'EMS Sedang Online, Silahkan Pencet sinyal!', 'info')
			else
				scene()
				TriggerServerEvent('hhfw:charge')
				QBCore.Functions.Notify('EMS', 'AI Revive sedang berlangsung!', 'info')
				Wait(600000)
				sibuk = false
			end
		else
			QBCore.Functions.Notify('EMS', 'Hanya bisa digunakan ketika pingsan!', 'error')
		end
	else
		QBCore.Functions.Notify('EMS', 'Colldown!', 'info')
	end
end)