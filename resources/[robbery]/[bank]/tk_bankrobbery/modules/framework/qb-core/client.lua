local client = {}

local QBCore = exports['qb-core']:GetCoreObject()

client.hasItems = function(items, amount)
    amount = amount or 1

    if client.Inventory == 'ox_inventory' then
        local count = exports['ox_inventory']:Search('count', items)

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
        return QBCore.Functions.HasItem(items, amount)
    end
end

return client
