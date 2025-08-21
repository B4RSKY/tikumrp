local utils = {}

utils.notify = function(message, notifType, timeOut)
    lib.notify({
        title = Locales['notify_title'],
        description = message,
        duration = timeOut,
        type = notifType,
        position = 'center-right',
    })
end

utils.createEvidence = function(coords)
    coords = coords or GetEntityCoords(cache.ped)
    TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
end

return utils
