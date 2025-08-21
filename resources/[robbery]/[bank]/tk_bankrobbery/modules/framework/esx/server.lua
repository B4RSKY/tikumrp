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

server.addMoney = function(Player, moneyType, amount, reason)
    if moneyType == 'cash' then
        Player.addAccountMoney('money', amount, reason)
        return true
    elseif moneyType == 'bank' then
        Player.addAccountMoney('bank', amount, reason)
        return true
    end

    return false
end

server.removeMoney = function(Player, moneyType, amount, reason)
    if moneyType == 'cash' then
        if Player.getAccount('money').money >= amount then
            Player.removeAccountMoney('money', amount, reason)
            return true
        else
            return false
        end
    elseif moneyType == 'bank' then
        if Player.getAccount('bank').money >= amount then
            Player.removeAccountMoney('bank', amount, reason)
            return true
        else
            return false
        end
    end

    return false
end

server.createLog = function(source, event, message)
    if Config.Logging == 'ox_lib' then
        lib.logger(source, event, message)
    elseif Config.Logging == 'esx' then
        ESX.DiscordLog('bankrobbery', event, 'default', message)
    end
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
    else
        local Player = server.GetPlayerFromId(source)

        if type(items) == 'table' then
            for item in pairs(items) do
                local item = Player.hasItem(item)
                if not item or item.count < amount then
                    return false
                end
            end

            return true
        else
            local hasItem = ESX.SearchInventory(items, amount)
            return hasItem >= amount
        end
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
    else
        local Player = server.GetPlayerFromId(source)
        if Player.canCarryItem(item, count) then
            Player.addInventoryItem(item, count, metadata, slot)
            return true
        else
            return false
        end
    end
end

server.getItem = function(source, itemName)
    if server.Inventory == 'ox_inventory' then
        local items = exports['ox_inventory']:Search(source, 1, itemName)
        return items[1]
    else
        local Player = server.GetPlayerFromId(source)
        local item = Player.getInventoryItem(itemName)
        return item
    end
end

server.setMetaData = function(source, slot, metadata)
    if server.Inventory == 'ox_inventory' then
        metadata.durability = math.floor(metadata.uses * 100 / Config.LaptopUses)
        exports['ox_inventory']:SetMetadata(source, slot, metadata)
    else
        local Player = server.GetPlayerFromId(source)
        
    end
end

server.registerUseableItem = ESX.RegisterUsableItem

return server
