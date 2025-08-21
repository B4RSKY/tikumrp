QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil

if not QBCore then return end

lib.callback.register('px_vehicleshop:getPlayerMoney', function(source, price, scroll)
    if scroll == 1 then
        local money = exports.ox_inventory:GetItemCount(source, 'cash')
        print(price)
        print(money)
        if tonumber(money) > tonumber(price) then
            return "cash"
        end
    else
        local moneyBank = exports['qb-banking']:GetAccountBalance(GetPlayerName(source))
        if tonumber(moneyBank) > tonumber(price) then
            return "bank"
        end
    end
end)


QBCore.Functions.CreateCallback('px_vehicleshop:getSocietyMoney', function(source, cb, price, job)
    local society = exports['qb-banking']:GetAccountBalance(job)
    if society >= price then
        exports['qb-banking']:RemoveMoney(job, price)
        cb(true)
    else
        cb(false)
    end
end)

RegisterServerEvent('px_vehicleshopBuyVehicle')
AddEventHandler('px_vehicleshopBuyVehicle', function(vehicle, price, action, r, g, b, job)
    printdbg('Prezzo' .. price)
    local loadFile = LoadResourceFile(GetCurrentResourceName(), "./vehicleSaved.json")
    if loadFile ~= nil then
        if Config.RemoveMoneyCompany then
            exports['qb-banking']:RemoveMoney(job, price)
        end
        local extract = json.decode(loadFile)
        if type(extract) == "table" then
            printdbg(extract)
            table.insert(extract, { name = vehicle, price = price, job = action, r = r, g = g, b = b })
            SaveResourceFile(GetCurrentResourceName(), "vehicleSaved.json", json.encode(extract, { indent = true }), -1)
        else
            local Table = {}
            table.insert(Table, { name = vehicle, price = price, job = action, r = r, g = g, b = b })
            SaveResourceFile(GetCurrentResourceName(), "vehicleSaved.json", json.encode(Table, { indent = true }), -1)
        end
    end
end)

RegisterServerEvent('px_vehicleshop:setVehicle')
AddEventHandler('px_vehicleshop:setVehicle', function(vehicle, plate, garage, price, result)
    printdbg(source)
    printdbg(vehicle)
    printdbg(plate)
    printdbg(garage)
    printdbg(price)
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(result)
    xPlayer.Functions.RemoveMoney(result, price, 'vehicle-bought-in-showroom')
    local cid = xPlayer.PlayerData.citizenid
    printdbg(xPlayer.PlayerData.license)
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
end)

RegisterServerEvent('px_vehicleshop:SellVehicle')
AddEventHandler('px_vehicleshop:SellVehicle', function(vehicle, plate, garage, player)
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
RegisterServerEvent('px_vehicleshop:returnVehicle')
AddEventHandler('px_vehicleshop:returnVehicle', function(vehicle, price, k, value)
    local returnPrice = price * 50 / 100
    exports['qb-banking']:AddMoney(value, returnPrice)
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