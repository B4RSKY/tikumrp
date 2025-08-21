local server = require 'modules.framework.server'
local utils = require 'modules.utils.server'

RegisterNetEvent('bankrobbery:server:RemoveGoldCard', function()
    local src = source
    server.removeItem(src, 'security_card_02', 1)
end)

RegisterNetEvent('bankrobbery:server:SetGoldCard', function()
    local src = source
    if Config.Banks['Pacific'].card then return end
    
    Config.Banks['Pacific'].card = true
    TriggerClientEvent('bankrobbery:client:SetGoldCard', -1)

    utils.doorUpdate(src, Config.Banks['Pacific'].cardDoor, false)
end)
