local Config = require 'stash.shared.config'

CreateThread(function()
    Wait(1000)
    for id, stashData in pairs(Config.Stash) do
        if stashData.target and type(stashData.target) == 'table' then
            exports.ox_target:addBoxZone({
                coords = stashData.target.coords,
                size = vec3(1.5, 1.5, 2),
                options = {
                    {
                        name = 'stash:' .. id,
                        label = stashData.target.label,
                        icon = stashData.target.icon,
                        groups = stashData.target.group,
                        onSelect = function()
                            exports.ox_inventory:openInventory('stash', id)
                        end
                    }
                }
            })
        end
    end
end)