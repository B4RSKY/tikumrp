local utils = {}

utils.alertPolice = function(bankType)
    if GetResourceState('ps-dispatch') ~= 'started' then return end

    if bankType == 'fleeca' then
        exports['ps-dispatch']:FleecaBankRobbery()
    elseif bankType == 'maze' then
        exports['ps-dispatch']:FleecaBankRobbery()
    elseif bankType == 'paleto' then
        exports['ps-dispatch']:PaletoBankRobbery()
    elseif bankType == 'pacific' then
        exports['ps-dispatch']:PacificBankRobbery()
    end
end

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
