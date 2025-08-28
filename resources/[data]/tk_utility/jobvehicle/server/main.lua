local Config = require 'jobvehicle.shared.config'
local QBCore = exports['qb-core']:GetCoreObject()

local function GetVehicleDataFromConfig(jobName, vehicleModel)
    for _, shopData in ipairs(Config.JobVehicleShop) do
        if shopData.job == jobName then
            if shopData.vehicle[vehicleModel] then
                return shopData.vehicle[vehicleModel]
            end
        end
    end
    return nil
end

RegisterNetEvent('tk_job:veh', function(jobName, vehicleModel, plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    local playerJob = Player.PlayerData.job.name
    if playerJob ~= jobName then
        print(('[tk_job] [EXPLOIT ATTEMPT] Player %s (citizenid: %s) tried to buy a vehicle for job "%s" while having job "%s"'):format(GetPlayerName(src), Player.PlayerData.citizenid, jobName, playerJob))
        DropPlayer(src, 'Terindikasi Percobaan Exploitasi')
        return
    end

    local vehicleConfig = GetVehicleDataFromConfig(jobName, vehicleModel)

    if not vehicleConfig then
        DropPlayer(src, 'Terindikasi Percobaan Exploitasi')
        print(('[tk_job] [EXPLOIT ATTEMPT] Player %s tried to buy an invalid vehicle model "%s" for job "%s"'):format(GetPlayerName(src), vehicleModel, jobName))
        return
    end

    local playerGrade = Player.PlayerData.job.grade.level
    if not vehicleConfig.forRank[playerGrade] then
        TriggerClientEvent('QBCore:Notify', src, 'SISTEM', 'Pangkat Anda tidak cukup untuk membeli kendaraan ini.', 'error')
        return
    end

    local price = vehicleConfig.price
    if Player.Functions.RemoveMoney('cash', price, 'bought-job-vehicle') then
        local citizenid = Player.PlayerData.citizenid
        local license = Player.PlayerData.license

        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            license,
            citizenid,
            vehicleModel,
            joaat(vehicleModel),
            json.encode({}),
            plate,
            1
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('QBCore:Notify', src, 'SISTEM', 'Berhasil Membeli Kendaraan', 'info')
            else
                Player.Functions.AddMoney('cash', price, 'buy-vehicle-failed-db')
                TriggerClientEvent('QBCore:Notify', src, 'SISTEM', 'Sistem Error, silahkan coba lagi', 'error')
            end
        end)
    else
        TriggerClientEvent('QBCore:Notify', src, 'SISTEM', 'Uang Anda tidak cukup', 'error')
    end
end)