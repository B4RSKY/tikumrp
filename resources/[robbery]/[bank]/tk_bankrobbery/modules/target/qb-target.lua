local target = {}

target.AddBoxZone = function(name, center, length, width, options, targetOptions)
    return exports['qb-target']:AddBoxZone(name, center, length, width, options, targetOptions)
end

target.AddTargetModel = function(models, options)
    exports['qb-target']:AddTargetModel(models, options)
end

target.AddLocalTargetEntity = function(entity, options)
    exports['qb-target']:AddTargetEntity(entity, options)
end

target.RemoveLocalTargetEntity = function(entity, labels)
    exports['qb-target']:RemoveTargetEntity(entity, labels)
end

return target
