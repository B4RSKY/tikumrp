local server = {}

local ESX = exports['es_extended']:getSharedObject()

server.GetPlayerFromId = ESX.GetPlayerFromId
server.GetPlayers = ESX.GetExtendedPlayers

server.isPlayerPolice = function(Player)
    return Player.job.name == 'police'
end

server.getPlayerData = function(Player)
    return {
        source = Player.source,
        identifier = Player.identifier,
        name = GetPlayerName(Player.source),
        jobName = Player.job.name,
        jobGrade = Player.job.grade,
        jobGradeLabel = Player.job.grade_label,
        cash = Player.getAccount('money').money,
        bank = Player.getAccount('bank').money,
        firstName = Player.get('firstName'),
        lastName = Player.get('lastName')
    }
end

server.exploitBan = function(source, reason)
    DropPlayer(source, 'You have been banned for cheating. Reason:' .. reason)
end

server.createLog = function(source, event, message)
    if Config.Logging == 'ox_lib' then
        lib.logger(source, event, message)
    elseif Config.Logging == 'esx' then
        ESX.DiscordLog('powerplant', event, 'default', message)
    end
end

server.removeItem = function(source, item, count, metadata, slot, ignoreTotal)
    if server.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:RemoveItem(source, item, count, metadata, slot, ignoreTotal)
    else
        local Player = server.GetPlayerFromId(source)
        Player.removeInventoryItem(item, count, metadata, slot)
        return true
    end
end

return server
