local utils = {}

utils.print = function(message)
    print('^3[' .. Config.Resource .. '] ^5' .. message .. '^7')
end

utils.notify = function(source, message, notifType, timeOut)
    TriggerClientEvent('ox_lib:notify', source, {
        title = Locales['notify_title'],
        description = message,
        duration = timeOut,
        type = notifType,
        position = 'center-right',
    })
end

utils.setBlackout = function(state)
    if state then
        if Config.Framework == 'qbcore' then
            exports['qb-weathersync']:setBlackout(true)
            TriggerClientEvent('police:client:DisableAllCameras', -1)
        elseif Config.Framework == 'esx' then

        elseif Config.Framework == 'qbox' then
            exports['qb-weathersync']:setBlackout(true)
            TriggerClientEvent('police:client:DisableAllCameras', -1)
        end
    else
        if Config.Framework == 'qbcore' then
            exports['qb-weathersync']:setBlackout(false)
            TriggerClientEvent('police:client:EnableAllCameras', -1)
        elseif Config.Framework == 'esx' then

        elseif Config.Framework == 'qbox' then
            exports['qb-weathersync']:setBlackout(false)
            TriggerClientEvent('police:client:EnableAllCameras', -1)
        end
    end
end

return utils
