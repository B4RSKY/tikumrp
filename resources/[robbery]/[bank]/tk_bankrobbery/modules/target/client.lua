local target = {}

if GetResourceState('ox_target'):find('start') then
    target = require 'modules.target.ox_target'
elseif GetResourceState('qb-target'):find('start') then
    target = require 'modules.target.qb-target'
else
    error('Target Not Found')
end

return target
