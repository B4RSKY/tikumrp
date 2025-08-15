local Config = require 'stash.shared.config'
local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('onServerResourceStart', function(resourceName)
    local GetCurrentResourceName = GetCurrentResourceName()
    if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName then
        for id, stashData in pairs(Config.Stash) do
            exports.ox_inventory:RegisterStash(id, stashData.label, stashData.slots, stashData.weight, false)
        end
    end
end)

local function ValidateStashTransaction(payload)

    if not payload then return false end
    
    local isDeposit = payload.fromType == 'player' and payload.toType == 'stash'
    local isWithdraw = payload.fromType == 'stash' and payload.toType == 'player'

    if not isDeposit and not isWithdraw then
        return true
    end

    local stashId = isDeposit and payload.toInventory or payload.fromInventory
    local stashData = Config.Stash[stashId]

    if not stashData then
        return true
    end

    if not stashData.jobs then
        return true
    end

    local source = payload.source
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end

    local playerJob = player.PlayerData.job.name
    local playerGrade = player.PlayerData.job.grade.level

    if playerJob ~= stashData.jobs then
        return false
    end

    if isDeposit then
        if playerGrade >= stashData.deposit_grade then
            return true
        else
            TriggerClientEvent('QBCore:Notify', source, 'SISTEM', 'Tidak memiliki akses untuk deposit.', 'error')
            return false
        end
    elseif isWithdraw then
        if playerGrade >= stashData.withdraw_grade then
            return true
        else
            TriggerClientEvent('QBCore:Notify', source, 'SISTEM', 'Tidak memiliki akses untuk withdraw.', 'error')
            return false
        end
    end

    return false
end

exports.ox_inventory:registerHook('swapItems', function(payload)
    local canProceed = ValidateStashTransaction(payload)
    return canProceed
end)