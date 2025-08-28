local Config = require 'carry.shared.config'
local QBCore = exports['qb-core']:GetCoreObject()

local carry = {
    InProgress = false,
    type = "",
    style = nil
}

local function ensureAnimDict(animDict)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end
    end
end

local function GetClosestPlayer(radius)
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    for _,playerId in ipairs(players) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(targetCoords-playerCoords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = playerId
                closestDistance = distance
            end
        end
    end
    if closestDistance ~= -1 and closestDistance <= radius then return closestPlayer else return nil end
end

local function StartCarry(styleName, targetPlayerId)
    if not Config.CarryStyles[styleName] then return end

    local finalTargetId = targetPlayerId 

    if not finalTargetId then
        local closestPlayer = GetClosestPlayer(3.0)
        if closestPlayer then
            finalTargetId = closestPlayer
        end
    end

    if finalTargetId then
        local targetSrc = GetPlayerServerId(finalTargetId)
        if targetSrc ~= -1 then
            TriggerServerEvent("CarryPeople:request", targetSrc, styleName)
        else
            QBCore.Functions.Notify("SISTEM", "Target tidak valid.", "error")
        end
    else
        QBCore.Functions.Notify("SISTEM", "Tidak ada pemain di dekat Anda.", "error")
    end
end

local function StopCarry()
    TriggerServerEvent("CarryPeople:stop")
end

RegisterCommand("carry", function() if not carry.InProgress then StartCarry('default') else StopCarry() end end, false)
RegisterCommand("carry2", function() if not carry.InProgress then StartCarry('piggyback') else StopCarry() end end, false)

CreateThread(function()
    exports.ox_target:addGlobalPlayer({
        {
            name = 'carry',
            icon = 'fa-solid fa-person',
            label = 'Carry 1',
            distance = 2.5,
            canInteract = function(entity)
                return not carry.InProgress
            end,
            onSelect = function(data)
                StartCarry('default', NetworkGetPlayerIndexFromPed(data.entity))
            end
        },
        {
            name = 'carry',
            icon = 'fa-solid fa-person',
            label = 'Carry 2',
            distance = 2.5,
            canInteract = function(entity)
                return not carry.InProgress
            end,
            onSelect = function(data)
                StartCarry('piggyback', NetworkGetPlayerIndexFromPed(data.entity))
            end
        }
    })
end)

RegisterNetEvent('CarryPeople:receiveRequest', function(carrierSrc, carrierName, styleName)
    if carry.InProgress then return end
    local alert = lib.alertDialog({
        header = 'Permintaan Menggendong',
        content = ('**%s** (ID: %s) ingin menggendong Anda. Apakah Anda setuju?'):format(carrierName, carrierSrc),
        centered = true,
        cancel = true,
        labels = { confirm = 'Terima', cancel = 'Tolak' }
    })
    if alert == 'confirm' then
        TriggerServerEvent('CarryPeople:accept', carrierSrc, styleName)
    else
        TriggerServerEvent('CarryPeople:deny', carrierSrc)
    end
end)

RegisterNetEvent('CarryPeople:startCarrying', function(targetSrc, styleName)
    local carryingData = Config.CarryStyles[styleName].personCarrying
    ensureAnimDict(carryingData.animDict)
    carry.InProgress = true
    carry.style = styleName
    carry.type = "carrying"
end)

RegisterNetEvent('CarryPeople:startBeingCarried', function(carrierSrc, styleName)
    local carrierPed = GetPlayerPed(GetPlayerFromServerId(carrierSrc))
    if not carrierPed or carrierPed == 0 then return end
    local carriedData = Config.CarryStyles[styleName].personCarried
    ensureAnimDict(carriedData.animDict)
    carry.InProgress = true
    carry.style = styleName
    carry.type = "beingcarried"
    AttachEntityToEntity(PlayerPedId(), carrierPed, 0, carriedData.attachX, carriedData.attachY, carriedData.attachZ, 0.0, 0.0, carriedData.attachSpin, false, false, false, false, 2, false)
end)

RegisterNetEvent("CarryPeople:cl_stop", function()
    carry.InProgress = false
    ClearPedSecondaryTask(PlayerPedId())
    DetachEntity(PlayerPedId(), true, false)
    carry.style = nil
    carry.type = ""
end)

CreateThread(function()
    while true do
        Wait(0)
        if carry.InProgress and carry.style then
            local styleData = Config.CarryStyles[carry.style]
            local animData = (carry.type == "beingcarried" and styleData.personCarried) or (carry.type == "carrying" and styleData.personCarrying)
            if animData and not IsEntityPlayingAnim(PlayerPedId(), animData.animDict, animData.anim, 3) then
                TaskPlayAnim(PlayerPedId(), animData.animDict, animData.anim, 8.0, -8.0, -1, animData.flag, 0, false, false, false)
            end
        end
    end
end)