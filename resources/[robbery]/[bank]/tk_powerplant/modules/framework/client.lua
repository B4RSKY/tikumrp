local client = {}

if GetResourceState('qbx_core') == 'started' then
    client = require 'modules.framework.qbox.client'
elseif GetResourceState('qb-core') == 'started' then
    client = require 'modules.framework.qb-core.client'
elseif GetResourceState('es_extended') == 'started' then
    client = require 'modules.framework.esx.client'
else
    error('Framework Not Found')
end

if GetResourceState('ox_inventory'):find('start') then
    client.Inventory = 'ox_inventory'
elseif GetResourceState('qb-inventory'):find('start') then
    client.Inventory = 'qb-inventory'
elseif GetResourceState('ps-inventory'):find('start') then
    client.Inventory = 'ps-inventory'
elseif GetResourceState('qs-inventory'):find('start') then
    client.Inventory = 'qs-inventory'
end

return client
