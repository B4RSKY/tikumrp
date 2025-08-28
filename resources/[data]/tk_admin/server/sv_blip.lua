RegisterNetEvent('admin:server:refreshBlips', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not QBCore.Functions.HasPermission(src, 'admin') and not QBCore.Functions.HasPermission(src, 'god')) then
        return
    end

    local blipData = {}
    local allPlayers = QBCore.Functions.GetPlayers()

    for i = 1, #allPlayers do
        local targetPlayerId = allPlayers[i]
        local targetPlayer = QBCore.Functions.GetPlayer(targetPlayerId)

        if targetPlayer then
            local targetPed = GetPlayerPed(targetPlayerId)
            local targetCoords = GetEntityCoords(targetPed)
            
            local playerData = {
                id = targetPlayerId,
                name = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname,
                job = targetPlayer.PlayerData.job.name,
                coords = targetCoords,
            }

            table.insert(blipData, playerData)
        end
    end

    TriggerClientEvent('admin:client:UpdatePlayerBlips', src, blipData)
end)