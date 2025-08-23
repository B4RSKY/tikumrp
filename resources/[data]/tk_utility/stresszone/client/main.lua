local Config = require 'stresszone.shared.config'
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local stressZones = {}
local inZone = false

local function isValidAnim()
    for _, anim in ipairs(Config.Animations) do
        if IsEntityPlayingAnim(cache.ped, anim[1], anim[2], 3) then
            return true
        end
    end
    return false
end

local function isValidScenario()
    for i = 1, #Config.Scenarios do
        if IsPedUsingScenario(cache.ped, Config.Scenarios[i]) then
            return true
        end
    end
    return false
end

local function stressLoop()
    inZone = true
    lib.notify({ title = 'Notification', description = 'Gunakan emote /e sit3/sit4/yoga untuk meredakan stress.', type = 'info', duration = 10000})
    lib.showTextUI('Relax Zone', {
        position = "left-center",
        icon = 'person',
    })
    CreateThread(function()
        while inZone do
            Wait(Config.Timer)
            if inZone then
                if isValidAnim() or isValidScenario() and PlayerData.metadata.stress > 0 then
                    TriggerServerEvent('hud:server:RelieveStress', math.random(5, 10))
                end
            end
        end
    end)
end

local function removeZones()
    for i = 1, #stressZones do
        if stressZones[i] then
            stressZones[i]:remove()
        end
    end
    table.wipe(stressZones)
end

local function createZones()
    for k, v in pairs(Config.Zones) do
        local zone = lib.zones.poly({ 
            points = v.points, 
            thickness = 20, 
            debug = false, 
            onEnter = stressLoop,
            onExit = function()
                inZone = false
                lib.hideTextUI()
            end, 
        })
        stressZones[#stressZones+1] = zone
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    createZones()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    table.wipe(PlayerData)
    removeZones()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res or not LocalPlayer.state.isLoggedIn then return end
    PlayerData = QBCore.Functions.GetPlayerData()
    createZones()
end)

AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end
    removeZones()
end)