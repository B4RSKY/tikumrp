local server = {}

server.GetPlayerFromId = function(source)
    return exports['qbx_core']:GetPlayer(source)
end

server.GetPlayers = function()
    return exports['qbx_core']:GetQBPlayers()
end

server.isPlayerPolice = function(Player)
    return (Player.PlayerData.job.type == 'leo' or Player.PlayerData.job.name == 'police') and Player.PlayerData.job.onduty
end

server.getPlayerData = function(Player)
    return {
        source = Player.PlayerData.source,
        identifier = Player.PlayerData.citizenid,
        license = Player.PlayerData.license,
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
    exports['qbox_core']:ExploitBan(source, reason)
end

server.addMoney = function(Player, moneyType, amount, reason)
    return Player.Functions.AddMoney(moneyType, amount, reason)
end

server.removeMoney = function(Player, moneyType, amount, reason)
    return Player.Functions.RemoveMoney(moneyType, amount, reason)
end

server.createLog = function(source, event, message)
    if Config.Logging == 'ox_lib' then
        lib.logger(source, event, message)
    elseif Config.Logging == 'qb' then
        TriggerEvent('qb-log:server:CreateLog', 'bankrobbery', event, 'default', message)
    end
end

server.registerUseableItem = function(item, data)
    exports['qbx_core']:CreateUseableItem(item, data)
end

server.hasItem = function(source, items, amount)
    amount = amount or 1

    if server.Inventory == 'ox_inventory' then
        local count = exports['ox_inventory']:Search(source, 'count', items)

        if type(items) == 'table' and type(count) == 'table' then
            for _, v in pairs(count) do
                if v < amount then
                    return false
                end
            end
    
            return true
        end
    
        return count >= amount
    end
end

server.removeItem = function(source, item, count, metadata, slot, ignoreTotal)
    if server.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:RemoveItem(source, item, count, metadata, slot, ignoreTotal)
    end
end

server.addItem = function(source, item, count, metadata, slot)
    if server.Inventory == 'ox_inventory' then
        if exports['ox_inventory']:CanCarryItem(source, item, count, metadata) then
            return exports['ox_inventory']:AddItem(source, item, count, metadata, slot)
        else
            utils.notify(source, Locales['notify_invent_full'], 'error', 5000)
            exports['ox_inventory']:CustomDrop(Locales['notify_title'], {
                { item, count, metadata }
            }, GetEntityCoords(GetPlayerPed(source)))
            return true
        end
    end
end

server.getItem = function(source, itemName)
    if server.Inventory == 'ox_inventory' then
        local items = exports['ox_inventory']:Search(source, 1, itemName)
        return items[1]
    end
end

server.setMetaData = function(source, slot, metadata)
    if server.Inventory == 'ox_inventory' then
        metadata.durability = math.floor(metadata.uses * 100 / Config.Laptop.uses)
        exports['ox_inventory']:SetMetadata(source, slot, metadata)
    end
end

return server
