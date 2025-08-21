local server = {}

if GetResourceState('qbx_core') == 'started' then
    server = require 'modules.framework.qbox.server'
elseif GetResourceState('qb-core') == 'started' then
    server = require 'modules.framework.qb-core.server'
elseif GetResourceState('es_extended') == 'started' then
    server = require 'modules.framework.esx.server'
else
    error('Framework Not Found')
end

if GetResourceState('ox_inventory'):find('start') then
    server.Inventory = 'ox_inventory'
elseif GetResourceState('qb-inventory'):find('start') then
    local exportFunction = nil

    local status, err = pcall(function()
        exportFunction = exports['qb-inventory']['CanAddItem']
    end)

    if status and type(exportFunction) == "function" then
        server.Inventory = 'qb-inventory'
    else
        server.Inventory = 'player'
    end
elseif GetResourceState('ps-inventory'):find('start') then
    server.Inventory = 'ps-inventory'
elseif GetResourceState('qs-inventory'):find('start') then
    server.Inventory = 'qs-inventory'
end

return server
