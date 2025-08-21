local server = require 'modules.framework.server'
local utils = require 'modules.utils.server'
local Rewards = require 'server.sv_rewards'

local vaultCode = math.random(1000, 9999)
local flags = 0

local stacks = {}

--- Functions

CreateStacks = function(bank)
    stacks[bank] = {}

    for k, v in ipairs(Config.Banks['Vault'].stacks) do
        local model = joaat('h4_prop_h4_cash_stack_01a')

        if v.type == 'gold' then
            model = joaat('h4_prop_h4_gold_stack_01a')
        end

        local object = CreateObject(model, v.coords.x, v.coords.y, v.coords.z, 1, 0, 0)
        SetEntityHeading(object, v.coords.w)
        FreezeEntityPosition(object, true)
        
        stacks[bank][#stacks[bank] + 1] = object
    end
end

ClearStacks = function(bank)
    if not stacks[bank] then return end

    for i = 1, #stacks[bank], 1 do
        if DoesEntityExist(stacks[bank][i]) then
            DeleteEntity(stacks[bank][i])
        end
    end

    stacks[bank] = nil
end

--- Events

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end

    ClearStacks('Vault')
end)

RegisterNetEvent('bankrobbery:server:HitByLaser', function()
    local src = source
    if Config.Banks['Vault'].lockdown then return end

    Config.Banks['Vault'].lockdown = true
    TriggerClientEvent('bankrobbery:client:VaultLockDown', -1)

    utils.notify(src, Locales['pacific_hitbylaser'], 'inform', 3000)
end)

RegisterNetEvent('bankrobbery:server:SetGoldHacked', function()
    local src = source
    local Player = server.GetPlayerFromId(src)
    if not Player then return end

    local PlayerData = server.getPlayerData(Player)

    if Config.Banks['Vault'].goldhacked then return end
    Config.Banks['Vault'].goldhacked = true

    utils.doorUpdate(src, Config.Banks['Vault'].laptopDoor, false)
    TriggerClientEvent('bankrobbery:client:SetGoldHacked', -1)

    utils.print(PlayerData.name .. ' (id: ' .. src .. ') Hacked Gold Laptop Vault') 
end)

RegisterNetEvent('bankrobbery:server:PrintCodes', function()
    local src = source
    local Player = server.GetPlayerFromId(src)
    if not Player then return end

    if not Config.Banks['Vault'].goldhacked then return end

    CreateStacks('Vault')
    
    TriggerClientEvent('var-ui:on', src, tostring(vaultCode))

    utils.print(PlayerData.name .. ' (id: ' .. src .. ') Received Vault Code') 
end)

RegisterNetEvent('bankrobbery:server:RemoveExplosive', function()
    local src = source
    server.removeItem(src, 'explosive', 1)
end)

RegisterNetEvent('bankrobbery:server:SetStackBusy', function(bank, index)
    local src = source
    local coords = GetEntityCoords(GetPlayerPed(src))

    if not Config.Banks[bank] or not Config.Banks[bank].stacks[index] then return end
    if #(coords - Config.Banks[bank].stacks[index].coords.xyz) > 5.0 then return end

    Config.Banks[bank].stacks[index].busy = true
    TriggerClientEvent('bankrobbery:client:SetStackBusy', -1, bank, index)
end)

RegisterNetEvent('bankrobbery:server:StackReward', function(netId, bank, index)
    local src = source
    local Player = server.GetPlayerFromId(src)
    if not Player or type(netId) ~= 'number' or not Config.Banks[bank] or not Config.Banks[bank].stacks[index] then return end

    local PlayerData = server.getPlayerData(Player)
    
    local entity = NetworkGetEntityFromNetworkId(netId)

    if entity ~= stacks[bank][index] then return end

    if #(GetEntityCoords(GetPlayerPed(src)) - Config.Banks[bank].stacks[index].coords.xyz) > 10 then return end
    if Config.Banks[bank].stacks[index].taken then return end

    TriggerClientEvent('bankrobbery:client:SetStackTaken', -1, bank, index)
    Config.Banks[bank].stacks[index].taken = true

    -- Delete stack
    if DoesEntityExist(stacks[bank][index]) then
        DeleteEntity(stacks[bank][index])
    end

    local bankType = Config.Banks[bank].type
    local rewardType = Config.Banks[bank].stacks[index].type

    if rewardType == 'money' then
        local receiveAmount = math.random(Rewards.Stacks[rewardType][bankType].minAmount, Rewards.Stacks[rewardType][bankType].maxAmount)
        
        local metaData = {
            worth = math.random(Rewards.Stacks[rewardType][bankType].minWorth, Rewards.Stacks[rewardType][bankType].maxWorth)
        }

        server.addItem(src, 'markedbills', receiveAmount, metaData)

        server.createLog(PlayerData.name, 'Stack Reward', PlayerData.name .. ' (identifier: ' .. PlayerData.identifier .. ' | id: ' .. src .. ')' .. ' Received ' .. receiveAmount .. ' x markedbills')
    elseif rewardType == 'gold' then
        local receiveAmount = math.random(Rewards.Stacks[rewardType][bankType].minAmount, Rewards.Stacks[rewardType][bankType].maxAmount)
        
        server.addItem(src, 'goldbar', receiveAmount)

        server.createLog(PlayerData.name, 'Stack Reward', PlayerData.name .. ' (identifier: ' .. PlayerData.identifier .. ' | id: ' .. src .. ')' .. ' Received ' .. receiveAmount .. ' x goldbar')
    end
end)

RegisterNetEvent('bankrobbery:server:AttemptCode', function(input)
    local src = source

    if input == vaultCode then
        Config.Banks['Vault'].code = true
        TriggerClientEvent('bankrobbery:client:CorrectCode', -1)
    else
        flags += 1

        if flags >= Config.BankSettings.VaultMaxFlags then
            Config.Banks['Vault'].lockdown = true
            TriggerClientEvent('bankrobbery:client:VaultLockDown', -1)
        end

        utils.notify(src, Locales['vault_flags']:format(flags, Config.BankSettings.VaultMaxFlags), 'error', 2500)
    end
end)

--- Items

server.registerUseableItem('explosive', function(source, item)
    TriggerClientEvent('explosive:UseExplosive', source)
end)

--- Threads

CreateThread(function()
    utils.print('Lower Vault Access Code: ' .. vaultCode)
end)
