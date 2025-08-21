local client = {}

local ESX = exports['es_extended']:getSharedObject()

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
        if type(items) == 'table' then
            for item in pairs(items) do
                if not ESX.SearchInventory(items, amount) then
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

return client
