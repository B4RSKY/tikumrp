local Config = require 'hungeralert.shared.config'
local QBCore = exports['qb-core']:GetCoreObject()

local lastAlertAt = {
    hunger = 0,
    thirst = 0
}

local function now()
    return GetGameTimer()
end

---@param kind 'hunger'|'thirst'
local function sendAlert(kind)
    local tnow = now()
    if (tnow - (lastAlertAt[kind] or 0)) < Config.CooldownMs then
        return
    end
    lastAlertAt[kind] = tnow

    lib.notify({
        title = 'Peringatan',
        description = Config.Notif[kind] or 'Status rendah',
        type = 'error',
        duration = 5000,
        position = 'top-right'
    })

    local soundName = (kind == 'hunger') and Config.Sound.lapar or Config.Sound.haus
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", Config.Sound.distance, soundName, Config.Sound.volume)
end

local function checkAndAlertFromMeta(meta)
    if not meta then return end

    local hunger = meta.hunger
    local thirst = meta.thirst
    if type(hunger) == 'number' and hunger < Config.Threshold then
        sendAlert('hunger')
    end
    if type(thirst) == 'number' and thirst < Config.Threshold then
        sendAlert('thirst')
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local data = QBCore.Functions.GetPlayerData()
    checkAndAlertFromMeta(data and data.metadata)
end)

CreateThread(function()
    while true do
        Wait(30000)
        local data = QBCore.Functions.GetPlayerData()
        if data and data.metadata then
            checkAndAlertFromMeta(data.metadata)
        end
    end
end)
