local server = require 'modules.framework.server'
local utils = require 'modules.utils.server'

RegisterNetEvent('bankrobbery:server:SetOutsideHacked', function()
    local src = source
    if Config.Banks['Paleto'].outsideHack then return end

    Config.Banks['Paleto'].outsideHack = true
    TriggerClientEvent('bankrobbery:client:SetOutsideHacked', -1)
end)

RegisterNetEvent('bankrobbery:server:RemoveGreenCard', function()
    local src = source
    server.removeItem(src, 'security_card_01', 1)
end)
