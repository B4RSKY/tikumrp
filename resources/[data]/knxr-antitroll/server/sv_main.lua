local QBCore = exports['qb-core']:GetCoreObject()
createTableIfNotExist()

lib.addCommand('troll', {
    help = 'Agar Player gabisa nembak,mukul, nabrak',
    params = {
        {
            name = 'id',
            type = 'Player ID',
            help = 'player',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local id = args.id
    local target = id

    if not target then
        TriggerClientEvent('QBCore:Notify', source, 'ID Tersebut tidak ada bos', 'error', 3500)
        return
    end

    ToggleTrollProtection(target)
end)

function ToggleTrollProtection(target, toogleOverride, timeOverride)
    TriggerClientEvent("knxr-antitroll:toggle", target, timeOverride)
end

RegisterNetEvent("knxr-antitroll:updateTime", function(time)
    local timeLeft = time
    local identifier = QBCore.Functions.GetIdentifier(source, 'steam')

    updateOrInsert(identifier, timeLeft)
end)

RegisterNetEvent("knxr-antitroll:onjoin", function()
    local source = source
    local identifier = QBCore.Functions.GetIdentifier(source, 'steam')
    local isNew = isNewPlayer(identifier)
    onJoin(source, identifier, isNew)
end)

function onJoin(source, identifier, isNew)
    if isNew then
        ToggleTrollProtection(source, true, Config.HowLong)
        return
    end

    local time = getTimeLeft(identifier)

    if time > 0 then
        TriggerClientEvent("knxr-antitroll:toggle", source, true, time)
        return
    end

    updateOrInsert(identifier, time)
end
