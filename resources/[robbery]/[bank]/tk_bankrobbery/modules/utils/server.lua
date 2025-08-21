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

utils.phoneMail = function(source, citizenid, sender, subject, message)
    if Config.Phone == 'QBCore' then
        -- Recent, using export
        exports['qb-phone']:sendNewMailToOffline(citizenid, {
            sender = sender,
            subject = subject,
            message = message
        })

        -- -- Older, using event
        -- TriggerEvent('qb-phone:server:sendNewMailToOffline', citizenid, {
        --     sender = sender,
        --     subject = subject,
        --     message = message
        -- })
    elseif Config.Phone == 'GKS' then
        exports['gksphone']:SendNewMail(source, {
            sender = sender,
            image = '/html/static/img/icons/mail.png',
            subject = subject,
            message = message
        })
    elseif Config.Phone == 'Qs' then
        TriggerEvent('qs-smartphone:server:sendNewMailToOffline', citizenid, {
            sender = sender,
            subject = subject,
            message = message
        })
    elseif Config.Phone == 'lb-phone' then
        local number = exports['lb-phone']:GetEquippedPhoneNumber(source)
        
        if number then
            local mail = exports['lb-phone']:GetEmailAddress(number)
            
            if mail then
                exports['lb-phone']:SendMail({
                    to = mail,
                    sender = sender,
                    subject = subject,
                    message = message
                })
            end

        end
    end
end

utils.doorUpdate = function(source, doorId, state)
    if Config.Doorlock == 'ox_doorlock' then
        state = state and 1 or 0
        exports['ox_doorlock']:setDoorState(exports['ox_doorlock']:getDoorFromName(doorId).id, state)
    elseif Config.Doorlock == 'qb-doorlock' then
        TriggerEvent('qb-doorlock:server:updateState', doorId, false, false, false, true, false, false, source)
    end
end

utils.scoreboardUpdate = function(entry, state)
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', entry, state)
end

utils.generatePassword = function(k)
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local string = ""

    for i = 1, k do
        local rand = math.random(#charset)
        string = string .. string.sub(charset, rand, rand)
    end

    return string
end

return utils