local server = {}

local QBCore = exports['qb-core']:GetCoreObject()

server.GetPlayerFromId = QBCore.Functions.GetPlayer
server.GetPlayers = QBCore.Functions.GetQBPlayers

server.isPlayerPolice = function(Player)
    return (Player.PlayerData.job.type == 'leo' or Player.PlayerData.job.name == 'police') and Player.PlayerData.job.onduty
end

server.getPlayerData = function(Player)
    return {
        source = Player.PlayerData.source,
        identifier = Player.PlayerData.citizenid,
        name = Player.PlayerData.name,
        jobName = Player.PlayerData.job.name,
        jobGrade = Player.PlayerData.job.grade.level,
        jobGradeLabel = Player.PlayerData.job.grade.name,
        cash = Player.PlayerData.money.cash,
        bank = Player.PlayerData.money.bank,
        crypto = Player.PlayerData.money.crypto,
        firstName = Player.PlayerData.charinfo.firstname,
        lastName = Player.PlayerData.charinfo.lastname
    }
end

server.exploitBan = function(source, reason)
    exports['qb-core']:ExploitBan(source, reason)
end

server.createLog = function(source, event, message)
    if Config.Logging == 'ox_lib' then
        lib.logger(source, event, message)
    elseif Config.Logging == 'qb' then
        TriggerEvent('qb-log:server:CreateLog', 'powerplant', event, 'default', message)
    end
end

server.removeItem = function(source, item, count, metadata, slot, ignoreTotal)
    if server.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:RemoveItem(source, item, count, metadata, slot, ignoreTotal)
    elseif server.Inventory == 'qb-inventory' then
        return exports['qb-inventory']:RemoveItem(source, item, count, slot, 'powerplant-remove')
    elseif server.Inventory == 'ps-inventory' then
        return exports['ps-inventory']:RemoveItem(source, item, count, slot)
    elseif server.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:RemoveItem(source, item, count, slot, metadata)
    else
        local Player = server.GetPlayerFromId(source)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], 'remove', count)
        return Player.Functions.RemoveItem(item, count, slot)
    end
end

return server
