local server = require 'modules.framework.server'
local utils = require 'modules.utils.server'

local powerState = {
    city = false,
    east = false
}

--- Functions

--- Function to return the amount of cops on duty
---@return getCopCount number - Amount of cops on duty
local getCopCount = function()
    local amount = 0
    local Players = server.GetPlayers()

    for _, Player in pairs(Players) do
        if server.isPlayerPolice(Player) then
            amount += 1
        end
    end

    return amount
end

--- Function to return whether or not the specific powerplant is hit
---@param plant string - powerState index, city or eastern power plant
---@return powerState boolean - Whether or not the powerplant is hit
local getPowerPlantState = function(plant)
    return powerState[plant]
end

--- Method to checks which stations are hit and trigger power plant explosions if needed
---@param playerId number - player server id
---@return nil
local checkStationHits = function(playerId)
    local plant = nil

    if Config.Locations[1].hit and Config.Locations[2].hit and Config.Locations[3].hit and Config.Locations[4].hit then
        plant = 'east'
    elseif Config.Locations[5].hit and Config.Locations[6].hit and Config.Locations[7].hit then
        plant = 'city'
    end

    if plant then
        if powerState[plant] then return end

        powerState[plant] = true

        Wait(10 * 1000) -- Gives the player 10 seconds to move away before explosion
        TriggerClientEvent('powerplant:client:PowerPlantExplosion', -1, plant)
        TriggerEvent('powerplant:server:PowerPlantHit', plant, playerId) -- Listen to in other resources
        utils.print('East Power Plant Hit')
        utils.setBlackout(true)
        
        TriggerClientEvent('chatMessage', -1, Locales['powerplant_hit_title'], 'error', Locales['powerplant_hit_text'])
        
        SetTimeout(1000 * 60 * 60, function() -- 60 minutes before reset
            if plant == 'east' then
                Config.Locations[1].hit = false
                Config.Locations[2].hit = false
                Config.Locations[3].hit = false
                Config.Locations[4].hit = false

                TriggerClientEvent('powerplant:client:SetStationStatus', -1, {1, 2, 3, 4}, false)
            elseif plant == 'city' then
                Config.Locations[5].hit = false
                Config.Locations[6].hit = false
                Config.Locations[7].hit = false

                TriggerClientEvent('powerplant:client:SetStationStatus', -1, {5, 6, 7}, false)
            end

            utils.setBlackout(false)
            powerState[plant] = false
            TriggerEvent('powerplant:server:PowerPlantRestored', plant) -- Listen to in other resources
            TriggerClientEvent('chatMessage', -1, Locales['powerplant_hit_title'], 'normal', Locales['powerplant_restored_text'])
        end)
    end
end

--- Function to return whether or not the specific powerplant is hit
---@param plant string - powerState index, city or eastern power plant
---@return nil
local adminPowerPlant = function(source, plant)
    if plant == 'city' then
        Config.Locations[5].hit = true
        Config.Locations[6].hit = true
        Config.Locations[7].hit = true

        TriggerClientEvent('powerplant:client:SetStationStatus', -1, {5, 6, 7}, true)
    elseif plant == 'east' then
        Config.Locations[1].hit = true
        Config.Locations[2].hit = true
        Config.Locations[3].hit = true
        Config.Locations[4].hit = true

        TriggerClientEvent('powerplant:client:SetStationStatus', -1, {1, 2, 3, 4}, true)
    end

    checkStationHits(source)
end

--- Events

RegisterNetEvent('powerplant:server:RemoveThermite', function()
    server.removeItem(source, Config.ThermiteItem, 1)
end)

RegisterNetEvent('powerplant:server:SetStationStatus', function(key, isHit)
    local src = source 

    -- Type Check
    if type(isHit) ~= 'boolean' or not Config.Locations[key] then return end

    -- Distance Check
    local pos = GetEntityCoords(GetPlayerPed(src))
    if #(pos - Config.Locations[key].coords) > 15 then return end

    -- Set powerstaion hit
    Config.Locations[key].hit = isHit

    utils.print('Station: ' .. key .. ' is hit successfully by ' .. GetPlayerName(src) .. ' (' .. src .. ')')
    TriggerClientEvent('powerplant:client:SetStationStatus', -1, key, isHit)
    checkStationHits(src)
end)

RegisterNetEvent('powerplant:server:ThermitePtfx', function(coords)
    TriggerClientEvent('powerplant:client:ThermitePtfx', -1, coords)
end)

--- Callbacks

lib.callback.register('powerplant:server:GetConfig', function(source)
    return Config, powerState
end)

lib.callback.register('powerplant:server:getCops', function(source)
    return getCopCount()
end)

--- Commands

lib.addCommand('powerplant', {
    help = Locales['command_help'],
    params = {
        {
            name = 'plant',
            type = 'string',
            help = Locales['command_arg_help'],
            optional = false
        }
    },
    restricted = 'qbcore.god'
}, function(source, args, raw)
    adminPowerPlant(args.plant)
end)

--- exports

exports('getPowerPlantState', getPowerPlantState)
exports('adminPowerPlant', adminPowerPlant)
