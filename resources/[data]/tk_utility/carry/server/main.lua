local QBCore = exports['qb-core']:GetCoreObject()

-- State Management
local carrying = {} -- carrying[carrierId] = targetId
local carried = {}  -- carried[targetId] = carrierId
local carryCooldown = {}
local COOLDOWN_SECONDS = 5

-- Net Events
RegisterNetEvent('CarryPeople:request', function(targetSrc, styleName)
    local source = source
    local sourceName = GetPlayerName(source)

    if carryCooldown[source] and GetGameTimer() < carryCooldown[source] then return end
    carryCooldown[source] = GetGameTimer() + (COOLDOWN_SECONDS * 1000)

    if carrying[source] or carried[source] or carried[targetSrc] then
        QBCore.Functions.Notify(source, "Anda atau target sedang dalam aksi lain.", "error")
        return
    end

    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(targetSrc)
    if not sourcePed or not targetPed or sourcePed == 0 or targetPed == 0 then return end
    
    local sourceCoords = GetEntityCoords(sourcePed)
    local targetCoords = GetEntityCoords(targetPed)
    
    if #(sourceCoords - targetCoords) <= 3.0 then
        TriggerClientEvent('CarryPeople:receiveRequest', targetSrc, source, sourceName, styleName)
        QBCore.Functions.Notify(source, "Permintaan telah dikirim...", "primary")
    else
        QBCore.Functions.Notify(source, "Tidak ada pemain di dekat Anda.", "error")
    end
end)

RegisterNetEvent('CarryPeople:deny', function(requesterSrc)
    QBCore.Functions.Notify(requesterSrc, "Permintaan Anda untuk menggendong telah ditolak.", "error")
end)

RegisterNetEvent('CarryPeople:accept', function(requesterSrc, styleName)
    local source = source
    local targetSrc = source
    local carrierSrc = requesterSrc

    if carrying[carrierSrc] or carried[carrierSrc] or carried[targetSrc] then return end

    local carrierPed = GetPlayerPed(carrierSrc)
    local targetPed = GetPlayerPed(targetSrc)
    if not carrierPed or not targetPed or carrierPed == 0 or targetPed == 0 then return end

    local carrierCoords = GetEntityCoords(carrierPed)
    local targetCoords = GetEntityCoords(targetPed)

    if #(carrierCoords - targetCoords) > 3.5 then
        QBCore.Functions.Notify(carrierSrc, "Target terlalu jauh.", "error")
        return
    end

    carrying[carrierSrc] = targetSrc
    carried[targetSrc] = carrierSrc

    TriggerClientEvent('CarryPeople:startCarrying', carrierSrc, targetSrc, styleName)
    TriggerClientEvent('CarryPeople:startBeingCarried', targetSrc, carrierSrc, styleName)
end)

RegisterNetEvent('CarryPeople:stop', function()
    local source = source
    local carrier = carried[source] or source
    local target = carrying[source] or (carried[source] and source)

    if not carrier or not target then return end

    TriggerClientEvent('CarryPeople:cl_stop', carrier)
    TriggerClientEvent('CarryPeople:cl_stop', target)
    
    carrying[carrier] = nil
    carried[target] = nil
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local carrier = carried[source] or source
    local target = carrying[source] or (carried[source] and source)
    
    if carrier and target then
        if source == carrier then
            TriggerClientEvent('CarryPeople:cl_stop', target)
        else
            TriggerClientEvent('CarryPeople:cl_stop', carrier)
        end
        carrying[carrier] = nil
        carried[target] = nil
    end
end)