local target = {}

target.AddBoxZone = function(name, center, length, width, options, targetOptions)
    return exports['qb-target']:AddBoxZone(name, center, length, width, options, targetOptions)
end

return target
