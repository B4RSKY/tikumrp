local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('tk_job:veh', function(vehData)
    if GetInvokingResource() then return end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local license = Player.PlayerData.license

    vehData.citizenid = citizenid
    vehData.license = license

    if Player.Functions.RemoveMoney('cash', vehData.price, 'bought-vehicle') then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            vehData.license,
            vehData.citizenid,
            vehData.model,
            joaat(vehData.model),
            json.encode(vehData.props or {}),
            vehData.plate,
            1
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('QBCore:Notify', source, 'SISTEM', 'Berhasil Membeli Kendaraan', 'info')
            else
                Player.Functions.AddMoney('cash', vehData.price, 'buy-vehicle-failed')
                TriggerClientEvent('QBCore:Notify', source, 'SISTEM', 'Sistem Error, Silahkan coba lagi', 'error')
            end
        end)
    else
        TriggerClientEvent('QBCore:Notify', source, 'SISTEM', 'Uang anda tidak Cukup', 'error')
    end
end)