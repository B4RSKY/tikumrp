local Framework
local FrameworkName

CreateThread(function()
    if GetResourceState('es_extended') == 'started' then
        Framework = exports['es_extended']:getSharedObject()
        FrameworkName = "ESX"
        print("[lex_handling] Menggunakan framework: ESX")
    elseif GetResourceState('qb-core') == 'started' then
        Framework = exports['qb-core']:GetCoreObject()
        FrameworkName = "QBCore"
        print("[lex_handling] Menggunakan framework: QBCore")
    elseif GetResourceState('qbox-core') == 'started' then
        Framework = exports['qbox-core']:GetCoreObject()
        FrameworkName = "Qbox"
        print("[lex_handling] Menggunakan framework: Qbox")
    else
        print("^1[lex_handling] Tidak ada framework yang dikenali ditemukan.^0")
    end
end)

RegisterNetEvent("lex_handling:server:checkPermission", function()
    local src = source
    local isAdmin = false

    if FrameworkName == "ESX" then
        local xPlayer = Framework.GetPlayerFromId(src)
        local group = xPlayer and xPlayer.getGroup() or nil
        isAdmin = (group == "admin" or group == "superadmin")

    elseif FrameworkName == "QBCore" or FrameworkName == "Qbox" then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            local group = Player.PlayerData.group or Player.PlayerData.permission or "user"
            isAdmin = (group == "admin" or group == "god" or group == "superadmin")
        end
    end

    if isAdmin then
        TriggerClientEvent("lex_handling:client:openUI", src)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            args = {"[ERROR]", "Hanya admin yang dapat menggunakan fitur ini."}
        })
    end
end)
