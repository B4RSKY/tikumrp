local server = require 'modules.framework.server'
local utils = require 'modules.utils.server'
local Rewards = require 'server.sv_rewards'

trollies = {}

robberyBusy = {
    fleeca = false,
    maze = false,
    paleto = false,
    pacific = false,
    vault = false
}

--- Functions

CreateTrollys = function(bank)
    trollies[bank] = {}

    for k, v in ipairs(Config.Banks[bank].trolly) do
        local model = joaat('hei_prop_hei_cash_trolly_01')

        if v.type == 'gold' then 
            model = joaat('ch_prop_gold_trolly_01a')
        end

        local trolly = CreateObject(model, v.coords.x, v.coords.y, v.coords.z - 1.0, 1, 0, 0)
        SetEntityHeading(trolly, v.coords.w)
        FreezeEntityPosition(trolly, true)
        trollies[bank][#trollies[bank] + 1] = trolly
    end
end

ClearTrollys = function(bank)
    if not trollies[bank] then return end

    for i = 1, #trollies[bank], 1 do
        if DoesEntityExist(trollies[bank][i]) then
            DeleteEntity(trollies[bank][i])
        end
    end

    trollies[bank] = nil
end

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

--- Resets all bool variables for a given bank so that it can be hit again
---@param bank string - Name of the bank
local ResetBank = function(bank)
    -- Door
    Config.Banks[bank].hacked = false
    Config.Banks[bank].policeClose = false

    -- lockers
    for i = 1, #Config.Banks[bank].lockers, 1 do
        Config.Banks[bank].lockers[i].busy = false
        Config.Banks[bank].lockers[i].taken = false
    end

    -- Trollys
    ClearTrollys(bank)

    for j = 1, #Config.Banks[bank].trolly, 1 do
        Config.Banks[bank].trolly[j].taken = false
    end

    -- Thermite spots
    if Config.Banks[bank].thermite then
        for k = 1, #Config.Banks[bank].thermite, 1 do
            Config.Banks[bank].thermite[k].hit = false
            utils.doorUpdate(src, Config.Banks[bank].thermite[k].doorId, true)
        end
    end

    -- Stackpiles of cash or gold
    if Config.Banks[bank].stacks then
        for h = 1, #Config.Banks[bank].stacks, 1 do
            Config.Banks[bank].stacks[h].busy = false
            Config.Banks[bank].stacks[h].taken = false
        end
    end

    -- Big Banks
    if bank == 'Paleto' then
        Config.Banks['Paleto'].outsideHack = false
    elseif bank == 'Pacific' then
        Config.Banks['Pacific'].card = false
    elseif bank == 'Vault' then
        Config.Banks['Vault'].lockdown = false
        Config.Banks['Vault'].goldhacked = false
        Config.Banks['Vault'].code = false
        ClearStacks('Vault')
    end

    robberyBusy[Config.Banks[bank].type] = false
    utils.scoreboardUpdate(Config.Banks[bank].type, false)
    TriggerClientEvent('bankrobbery:client:ResetBank', -1, bank)
    utils.print('Resetting ' .. bank)
end

SwapTrolly = function(bank, index, entity)
    local newTrollyModel = joaat('hei_prop_hei_cash_trolly_03')
    
    if Config.Banks[bank].trolly[index].type == 'gold' then
        newTrollyModel = joaat('ch_prop_gold_trolly_empty')
    end

    local newTrolly = CreateObject(newTrollyModel, Config.Banks[bank].trolly[index].coords.x, Config.Banks[bank].trolly[index].coords.y, Config.Banks[bank].trolly[index].coords.z - 1.0, 1, 0, 0)
    SetEntityHeading(newTrolly, Config.Banks[bank].trolly[index].coords.w)
    DeleteEntity(entity)
    trollies[bank][index] = newTrolly
    FreezeEntityPosition(newTrolly, true)
end

--- Events

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end

    for k, v in pairs(trollies) do
        for i = 1, #v, 1 do
            if DoesEntityExist(v[i]) then
                DeleteEntity(v[i])
            end
        end
    end
end)

RegisterNetEvent('bankrobbery:server:SetBankHacked', function(bank)
    local src = source
    local Player = server.GetPlayerFromId(src)
    if not Player then return end

    local PlayerData = server.getPlayerData(Player)

    if not Config.Banks[bank] then return end
    if Config.Banks[bank].hacked then return end

    Config.Banks[bank].hacked = true
    robberyBusy[Config.Banks[bank].type] = true
    utils.scoreboardUpdate(Config.Banks[bank].type, true)

    CreateTrollys(bank)

    utils.phoneMail(src, PlayerData.identifier, Locales['mail_sender'], bank, Locales['mail_message'])

    SetTimeout(Config.BankSettings.VaultUnlockTime * 1000, function()
        TriggerClientEvent('bankrobbery:client:SetBankHacked', -1, bank)
    end)

    SetTimeout(Config.Cooldown[Config.Banks[bank].type] * 60 * 1000, function() -- Cooldown timer
        ResetBank(bank)
    end)
end)

RegisterNetEvent('bankrobbery:server:PDClose', function(data)
    local src = source
    local Player = server.GetPlayerFromId(src)
    if not Player then return end

    local bank = data.bank
    if not Config.Banks[bank] then return end
    
    if not server.isPlayerPolice(Player) then return end

    Config.Banks[bank].policeClose = not Config.Banks[bank].policeClose
    TriggerClientEvent('bankrobbery:client:PDClose', -1, bank)
end)

RegisterNetEvent('bankrobbery:server:SetTrollyBusy', function(bank, index)
    local src = source
    local coords = GetEntityCoords(GetPlayerPed(src))
    if not Config.Banks[bank] or not Config.Banks[bank].trolly[index] then return end
    if #(coords - Config.Banks[bank].trolly[index].coords.xyz) > 2.0 then return end

    Config.Banks[bank].trolly[index].busy = true
    TriggerClientEvent('bankrobbery:client:SetTrollyBusy', -1, bank, index)
end)

RegisterNetEvent('bankrobbery:server:TrollyReward', function(netId, bank, index)
    local src = source
    local Player = server.GetPlayerFromId(src)
    if not Player then return end

    local PlayerData = server.getPlayerData(Player)

    if type(netId) ~= 'number' or not Config.Banks[bank] or not Config.Banks[bank].trolly[index] then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity ~= trollies[bank][index] then return end
    
    if #(GetEntityCoords(GetPlayerPed(src)) - Config.Banks[bank].trolly[index].coords.xyz) > 10 then return end
    if Config.Banks[bank].trolly[index].taken then return end

    TriggerClientEvent('bankrobbery:client:SetTrollyTaken', -1, bank, index)
    Config.Banks[bank].trolly[index].taken = true

    SwapTrolly(bank, index, entity)

    local bankType = Config.Banks[bank].type
    local rewardType = Config.Banks[bank].trolly[index].type

    if rewardType == 'money' then
        local receiveAmount = math.random(Rewards.Trollys[rewardType][bankType].minAmount, Rewards.Trollys[rewardType][bankType].maxAmount)
        
        local metaData = {
            worth = math.random(Rewards.Trollys[rewardType][bankType].minWorth, Rewards.Trollys[rewardType][bankType].maxWorth)
        }

        server.addItem(src, 'markedbills', receiveAmount, metaData)

        server.createLog(PlayerData.name, 'Trolly Reward', PlayerData.name .. ' (identifier: ' .. PlayerData.identifier .. ' | id: ' .. src .. ')' .. ' Received ' .. receiveAmount .. ' x markedbills')
    elseif rewardType == 'gold' then
        local receiveAmount = math.random(Rewards.Trollys[rewardType][bankType].minAmount, Rewards.Trollys[rewardType][bankType].maxAmount)

        server.addItem(src, 'goldbar', receiveAmount)

        server.createLog(PlayerData.name, 'Trolly Reward', PlayerData.name .. ' (identifier: ' .. PlayerData.identifier .. ' | id: ' .. src .. ')' .. ' Received ' .. receiveAmount .. ' x goldbar')
    end
end)

RegisterNetEvent('bankrobbery:server:SetLockerBusy', function(bank, index)
    local src = source
    local coords = GetEntityCoords(GetPlayerPed(src))

    if not Config.Banks[bank] or not Config.Banks[bank].lockers[index] then return end
    if #(coords - Config.Banks[bank].lockers[index].coords.xyz) > 5.0 then return end

    Config.Banks[bank].lockers[index].busy = true
    TriggerClientEvent('bankrobbery:client:SetLockerBusy', -1, bank, index)
end)

RegisterNetEvent('bankrobbery:server:LockerReward', function(bank, index)
    local src = source
    local Player = server.GetPlayerFromId(src)
    if not Player then return end

    local PlayerData = server.getPlayerData(Player)

    if not Config.Banks[bank] or not Config.Banks[bank].lockers[index] then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - Config.Banks[bank].lockers[index].coords.xyz) > 10 then return end
    if Config.Banks[bank].lockers[index].taken then return end

    TriggerClientEvent('bankrobbery:client:SetLockerTaken', -1, bank, index)
    Config.Banks[bank].lockers[index].taken = true

    local bankType = Config.Banks[bank].type

    if math.random(100) < Rewards.Lockers[bankType].rareChance then -- Rare item loot
        server.addItem(src, Rewards.Lockers[bankType].rareItem, 1)
        server.createLog(PlayerData.name, 'Locker Reward', PlayerData.name .. ' (identifier: ' .. PlayerData.identifier .. ' | id: ' .. src .. ')' .. ' Received 1 x ' .. Rewards.Lockers[bankType].rareItem)
    else
        local randomItem = Rewards.Lockers[bankType].items[math.random(#Rewards.Lockers[bankType].items)]
        local receiveAmount = math.random(Rewards.Lockers[bankType].amount.minAmount, Rewards.Lockers[bankType].amount.maxAmount)
        
        server.addItem(src, randomItem, receiveAmount)
        server.createLog(PlayerData.name, 'Locker Reward', PlayerData.name .. ' (identifier: ' .. PlayerData.identifier .. ' | id: ' .. src .. ')' .. ' Received ' .. receiveAmount .. ' x ' .. randomItem)
    end
end)

RegisterNetEvent('bankrobbery:server:RemoveThermite', function()
    local src = source
    server.removeItem(src, 'thermite', 1)
end)

RegisterNetEvent('bankrobbery:server:SetThermiteHit', function(bank, index)
    Config.Banks[bank].thermite[index].hit = true
    TriggerClientEvent('bankrobbery:client:SetThermiteHit', -1, bank, index)
end)

RegisterNetEvent('bankrobbery:server:ThermitePtfx', function(bank, index)
    local src = source
    local coords = Config.Banks[bank].thermite[index].ptfx
    TriggerClientEvent('bankrobbery:client:ThermitePtfx', -1, coords)

    Wait(27000)
    utils.doorUpdate(src, Config.Banks[bank].thermite[index].doorId, false)
end)

--- Callbacks

lib.callback.register('bankrobbery:server:GetConfig', function(source)
    return Config
end)

lib.callback.register('bankrobbery:server:CanAttemptBankRobbery', function(source, bank)
    local src = source
    local bankType = Config.Banks[bank].type

    if robberyBusy[bankType] then
        utils.notify(src, Locales['bank_cooldown'], 'error', 4000)
        return false
    elseif getCopCount() < Config.MinCops[bankType] then
        utils.notify(src, Locales['not_enough_cops']:format(Config.MinCops[bankType]), 'error', 4000)
        return false
    else
        return true
    end
end)

--- Items

server.registerUseableItem('thermite', function(source, item)
    TriggerClientEvent('thermite:UseThermite', source)
end)
