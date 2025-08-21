local target = require 'modules.target.client'

local onEnterPoint = function(point)
    local pedModel = point.pedModel
    lib.requestModel(pedModel)
    local ped = CreatePed(0, pedModel, point.coords.x, point.coords.y, point.coords.z - 1.0, point.heading, false, false)

    SetModelAsNoLongerNeeded(pedModel)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    target.AddLocalTargetEntity(ped, {
        options = {
            {
                type = 'server',
                event = 'bankrobbery:server:BuyLaptop',
                icon = 'fas fa-hand-holding',
                label = Locales['laptop_target_label'],
                colour = point.colour
            }
        },
        distance = 1.5,
    })

    point.entity = ped
end

local onExitPoint = function(point)
	local entity = point.entity

	if not entity then return end

    target.RemoveLocalTargetEntity(entity, {
        Locales['laptop_target_label']
    })

    SetEntityAsMissionEntity(entity, false, true)
    DeleteEntity(entity)

	point.entity = nil
end

for k, v in pairs(Config.Laptop) do
    local point = lib.points.new({
        coords = v.coords.xyz,
        distance = 60,
        onEnter = onEnterPoint,
        onExit = onExitPoint,
        colour = k,
        heading = v.coords.w,
        pedModel = v.pedModel,
    })        
end
