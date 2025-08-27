QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil

if not QBCore then return end

lib.callback.register('vehicleshop:getPlayerMoney', function(source, price, scroll)
    local Player = QBCore.Functions.GetPlayer(source)
    if scroll == 1 then
        local money = exports.ox_inventory:GetItemCount(source, 'cash')
        if money and price and (tonumber(money) >= tonumber(price)) then
            return "cash"
        end
    else
        local moneyBank = Player.Functions.GetMoney('bank')
        if moneyBank and price and (tonumber(moneyBank) >= tonumber(price)) then
            return "bank"
        end
    end
    return nil 
end)


QBCore.Functions.CreateCallback('vehicleshop:getSocietyMoney', function(source, cb, price, job)
    local society = exports['Renewed-Banking']:getAccountMoney(job)
    if society >= price then
        exports['Renewed-Banking']:removeAccountMoney(job, price)
        cb(true)
    else
        cb(false)
    end
end)

local function GetVehicleData(modelName)
    if not modelName then return nil end
    for _, vehicle in ipairs(Config.Vehicles) do
        if vehicle.model == modelName then
            return vehicle
        end
    end
    return nil
end

RegisterServerEvent('vehicleshop:secureBuyVehicle')
AddEventHandler('vehicleshop:secureBuyVehicle', function(vehicleModel, plate, garage, paymentMethod)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    
    if not xPlayer then return end
    if paymentMethod ~= 'cash' and paymentMethod ~= 'bank' then return end
    local vehicleData = GetVehicleData(vehicleModel)
    if not vehicleData then
        local namaSteam	= GetPlayerName(src) or "unknown"
        local steamhex  = GetPlayerIdentifier(src) or "steam:unknown"
        local isi = ( '**`📦` Mencoba Exploit: Invalid vehicle model**\n\n' ..
            '**`👤` Player**: **%s**\n' ..
            '**`👤` Nama steam**: **%s**\n' ..
            '**`🎮` Steam Hex**: `%s`\n\n' ..
            '**`📗` CID**: `%s`\n' ..
            '**`🚗` Kendaraan**: `%s`\n'
        ):format(xPlayer.PlayerData.name, namaSteam, steamhex, xPlayer.PlayerData.citizenid, vehicleModel)
        TriggerEvent('qb-log:server:CreateLog', 'vehicleshop', 'VEHICLESHOP', 'ungu', isi, false)
        return
    end

    local correctPrice = tonumber(vehicleData.price)
    local accountType = paymentMethod

    if xPlayer.Functions.GetMoney(accountType) >= correctPrice then
        xPlayer.Functions.RemoveMoney(accountType, correctPrice, 'vehicle-shop-purchase')
        
        MySQL.insert(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, garage) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            {
                xPlayer.PlayerData.license,
                xPlayer.PlayerData.citizenid,
                vehicleData.model,
                GetHashKey(vehicleData.model),
                '{}',
                plate,
                1,
                garage
            },
            function()
                TriggerClientEvent('QBCore:Notify', src, "Selamat, Anda telah membeli " .. (vehicleData.name or vehicleData.model) .. "!", "success", 8000)
                local namaSteam	= GetPlayerName(src) or "unknown"
                local steamhex  = GetPlayerIdentifier(src) or "steam:unknown"
                local isi = ( '**`📦` Membeli Kendaraan**\n\n' ..
                    '**`👤` Player**: **%s**\n' ..
                    '**`👤` Nama steam**: **%s**\n' ..
                    '**`🎮` Steam Hex**: `%s`\n\n' ..
                    '**`📗` CID**: `%s`\n' ..
                    '**`🚗` Kendaraan**: `%s`\n'..
                    '**`💵` Harga**: `%s`\n'..
                    '**`🪙` Methode**: `%s`\n'
                ):format(xPlayer.PlayerData.name, namaSteam, steamhex, xPlayer.PlayerData.citizenid, vehicleData.name, correctPrice, accountType)
                TriggerEvent('qb-log:server:CreateLog', 'vehicleshop', 'VEHICLESHOP', 'ungu', isi, false)
            end)
    else
        TriggerClientEvent('QBCore:Notify', src, "Uang Anda tidak cukup untuk membeli kendaraan ini.", "error", 8000)
    end
end)

RegisterServerEvent('vehicleshop:secureStockVehicle')
AddEventHandler('vehicleshop:secureStockVehicle', function(vehicleModel, action, r, g, b, job)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)

    if not xPlayer then return end

    if xPlayer.PlayerData.job.name ~= job or job ~= "cardealer" then
        print(string.format("[PX-VEHICLESHOP EXPLOIT] Player %s (Job: %s) tried to stock vehicle as a %s.", xPlayer.PlayerData.name, xPlayer.PlayerData.job.name, job))
        return
    end

    local vehicleData = GetVehicleData(vehicleModel)
    if not vehicleData then
        print(string.format("[PX-VEHICLESHOP EXPLOIT] Dealer %s tried to stock an invalid vehicle model: %s", xPlayer.PlayerData.name, vehicleModel))
        return
    end
    local correctPrice = tonumber(vehicleData.price)
    if Config.RemoveMoneyCompany then
        exports['qb-management']:RemoveMoney(job, correctPrice)
    end

    local loadFile = LoadResourceFile(GetCurrentResourceName(), "./vehicleSaved.json")
    local extract = loadFile and json.decode(loadFile) or {}
    
    if type(extract) ~= "table" then
        extract = {}
    end

    table.insert(extract, { name = vehicleData.model, price = correctPrice, job = action, r = r, g = g, b = b })
    SaveResourceFile(GetCurrentResourceName(), "vehicleSaved.json", json.encode(extract, { indent = true }), -1)
    TriggerClientEvent('QBCore:Notify', src, "Anda berhasil menambahkan " .. (vehicleData.name or vehicleData.model) .. " ke stok.", "success")
end)

RegisterServerEvent('vehicleshop:SellVehicle')
AddEventHandler('vehicleshop:SellVehicle', function(vehicle, plate, garage, player)
    printdbg(vehicle)
    printdbg(plate)
    printdbg(garage)
    printdbg(player)
    local _source = player
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    TriggerClientEvent('ox_lib:notify', _source, {
        type = 'success',
        title = locale("px_notify_sell") .. plate,
        position = 'top',
        description = '',
        5000
    })
    local cid = xPlayer.PlayerData.citizenid
    MySQL.insert(
        'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, garage) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {
            xPlayer.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            1,
            garage
        })
    TriggerClientEvent('qb-vehiclekeys:client:AddKeys', player, plate)
end)

--BossMenu
RegisterServerEvent('vehicleshop:returnVehicle')
AddEventHandler('vehicleshop:returnVehicle', function(vehicle, price, k, value)
    local returnPrice = price * 50 / 100
    exports['Renewed-Banking']:addAccountMoney(value, returnPrice)
    local loadFile = LoadResourceFile(GetCurrentResourceName(), "./vehicleSaved.json ")
    if loadFile ~= nil then
        local extract = json.decode(loadFile)
        if type(extract) == "table" then
            for k, v in ipairs(extract) do
                if v.name == vehicle then
                    printdbg(v.coords)
                    printdbg(k)
                    table.remove(extract, k)
                    SaveResourceFile(GetCurrentResourceName(), "vehicleSaved.json",
                        json.encode(extract, { indent = true }), -1)
                end
            end
        end
    end
end)

lib.callback.register('vehicleshop:isPlateTaken', function(source, cb, plate)
	MySQL.scalar('SELECT plate FROM player_vehicles WHERE plate = ?', {plate},
	function(result)
		return (result ~= nil)
	end)
end)