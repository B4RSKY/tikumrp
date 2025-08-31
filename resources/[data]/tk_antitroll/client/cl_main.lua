local QBCore = exports['qb-core']:GetCoreObject()
local isTimerInstance = false
local isTimerRunning = false
local hasProtection = false
local timeLeft = 0
local timeToSafe = Config.TimeToSave

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    TriggerServerEvent("tk_antitroll:onjoin", false)
end)

local function setUiShow(bool)
    SendNUIMessage({
        type = "show",
        show = bool
    })
end

local function updateUiTime(timeLeft)
    local jam = math.floor((timeLeft % (60 * 24)) / 60)
    local menit = timeLeft % 60
    SendNUIMessage({
        type = "update",
        jamLeft = jam,
        minleft = menit
    })
end

local function updateTimeToDatabase(overrideTime)
    TriggerServerEvent("tk_antitroll:updateTime", overrideTime or timeLeft)
end

local function startTimer()
    local interval = timeToSafe

    updateTimeToDatabase()

    CreateThread(function()
        isTimerInstance = true
        isTimerRunning = true
        while hasProtection do
            if interval == timeToSafe or timeLeft <= 0 then
                interval = 0
                setUiShow(true)
                updateTimeToDatabase()
            end

            interval = interval + 1

            if timeLeft <= 0 then
                stopAntiTroll()
                isTimerInstance = false
                return
            end

            timeLeft = timeLeft - 1

            updateUiTime(timeLeft)
            Wait(1000 * 60)
        end
        isTimerRunning = false -- stop the Timer thread
    end)
end

local function startAntiTroll()
    if not isTimerInstance then
        startTimer()
    end
    setUiShow(true)

    -- Anti VDM
    if Config.DisableVDM then
        SetWeaponDamageModifier(-1553120962, 0.0)
    end

    -- Anti Driveby
    if not Config.DriveBy then
        SetPlayerCanDoDriveBy(PlayerId(), false)
    end

    if Config.DisablePunching then
        CreateThread(function()
            while hasProtection do
                Wait(5)
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
            end
        end)
    end

    if Config.DisableShooting then
        CreateThread(function()
            while hasProtection do
                Wait(5)
                local senjata = GetSelectedPedWeapon(cache.ped)
                if senjata == GetHashKey("WEAPON_MACHETE") then
                    EnableControlAction(0, 140, true)
                    EnableControlAction(0, 141, true)
                    EnableControlAction(0, 142, true)
                else
                    DisablePlayerFiring(PlayerId(), true)
                end
            end
        end)
    end

    if Config.DisablePunchingDamage then
        SetWeaponDamageModifier(-1569615261, 0.0)
    end
end

local function stopAntiTroll()
    hasProtection = false
    timeLeft = 0

    isTimerInstance = false

    -- Anti VDM
    if Config.DisableVDM then
        SetWeaponDamageModifier(-1553120962, 1.0)
    end

    -- Anti Driveby
    if not Config.DriveBy then
        SetPlayerCanDoDriveBy(PlayerId(), true)
    end

    if Config.DisablePunching then
        EnableControlAction(0, 140, true)
        EnableControlAction(0, 141, true)
        EnableControlAction(0, 142, true)
    end

    if Config.DisablePunchingDamage then
        SetWeaponDamageModifier(-1569615261, 1.0)
    end
    setUiShow(false)
    isTimerRunning = false -- stop the Timer thread
end

RegisterNetEvent("tk_antitroll:toggle", function(toggle, timeOverride)
    local jam = 5
    local menit = 60
    hasProtection = toggle or not hasProtection
    timeLeft = timeOverride or ((jam * 60) + menit)

    if hasProtection then
        startAntiTroll()
        updateTimeToDatabase(timeLeft)
    else
        stopAntiTroll()
        updateTimeToDatabase(0)
    end
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload")
AddEventHandler("QBCore:Client:OnPlayerUnload", function()
    stopAntiTroll()
end)