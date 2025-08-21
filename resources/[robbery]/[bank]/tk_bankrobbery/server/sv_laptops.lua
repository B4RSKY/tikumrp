local server = require 'modules.framework.server'
local utils = require 'modules.utils.server'

RegisterNetEvent('bankrobbery:server:BuyLaptop', function(data)
    local src = source
    local Player = server.GetPlayerFromId(src)
    if not Player then return end

    local PlayerData = server.getPlayerData(Player)
    
    local colour = data.colour
    if not Config.Laptop[colour] then return end

    local pos = GetEntityCoords(GetPlayerPed(src))
    if #(pos - Config.Laptop[colour].coords.xyz) > 10.0 then return end

    local requiredItem = Config.Laptop[colour].usb
    local price = Config.Laptop[colour].price
    local moneyType = Config.LaptopMoneyType
    local laptopItem = Config.Laptop[colour].reward

    local hasItem = server.hasItem(src, requiredItem)

    if hasItem then
        if PlayerData[moneyType] >= price and server.removeMoney(Player, moneyType, price, 'bankrobbery-buy-laptop') then
            -- Remove USB
            server.removeItem(src, requiredItem, 1)

            -- Add Laptop
            local metaData = { 
                uses = Config.LaptopUses,
                durability = 100
            }

            server.addItem(src, laptopItem, 1, metaData)

            -- Log
            server.createLog(PlayerData.name, 'Laptop Purchased', PlayerData.firstName .. ' ' .. PlayerData.lastName .. ' (' .. PlayerData.name .. ' - ' .. PlayerData.identifier .. ') Purchased ' .. laptopItem .. ' for: ' .. price .. ' ' .. moneyType)
        else
            utils.notify(src, Locales['laptop_not_enough']:format(Config.LaptopMoneyType), 'error', 3000)
        end
    else
        utils.notify(src, Locales['missing_items'], 'error', 3000)
    end
end)

RegisterNetEvent('bankrobbery:server:LaptopDamage', function(itemName)
    local src = source

    local item = server.getItem(src, itemName)
    if not item then
        server.exploitBan(src, 'bankrobbery-laptopdamage')
        return
    end

    local uses = item.info?.uses or item.metadata?.uses

    if not uses then
        local metadata = {
            uses = Config.LaptopUses - 1
        }

        server.setMetaData(src, item.slot, metadata)

        utils.print(GetPlayerName(src) .. ' Laptop has no metadata.uses!^7')
        return
    end

    if uses - 1 <= 0 then
        server.removeItem(src, item.name, 1, nil, item.slot)
    else
        local metadata = {
            uses = uses - 1
        }

        server.setMetaData(src, item.slot, metadata)
    end
end)
