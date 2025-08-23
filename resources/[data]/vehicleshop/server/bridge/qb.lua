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
        local moneyBank = exports['Renewed-Banking']:getAccountMoney(GetPlayerName(source))
        if tonumber(moneyBank) > tonumber(price) then
            return "bank"
        end
    end
end)


QBCore.Functions.CreateCallback('px_vehicleshop:getSocietyMoney', function(source, cb, price, job)
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

RegisterServerEvent('px_vehicleshop:secureBuyVehicle')
AddEventHandler('px_vehicleshop:secureBuyVehicle', function(vehicleModel, plate, garage)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    
    if not xPlayer then return end
    local vehicleData = GetVehicleData(vehicleModel)
    if not vehicleData then
        print(string.format("[PX-VEHICLESHOP EXPLOIT] Player %s (CitizenID: %s) tried to buy an invalid vehicle model: %s", xPlayer.PlayerData.name, xPlayer.PlayerData.citizenid, vehicleModel))
        -- Opsional: Tambahkan kick atau ban di sini jika perlu
        -- exports.ghmattimysql:execute("INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (@name, @license, @discord, @ip, @reason, @expire, @bannedby)", { ... })
        return
    end

    local correctPrice = tonumber(vehicleData.price)
    local accountType = 'cash' or 'bank'

    if xPlayer.Functions.GetMoney(accountType) >= correctPrice then
        -- 5. Eksekusi: Kurangi uang dan masukkan mobil ke database
        xPlayer.Functions.RemoveMoney(accountType, correctPrice, 'vehicle-shop-purchase')
        
        MySQL.insert(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, garage) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            {
                xPlayer.PlayerData.license,
                xPlayer.PlayerData.citizenid,
                vehicleData.model, -- Gunakan model yang sudah divalidasi
                GetHashKey(vehicleData.model),
                '{}',
                plate,
                1,
                garage
            },
            function()
                TriggerClientEvent('QBCore:Notify', src, "Selamat, Anda telah membeli " .. (vehicleData.name or vehicleData.model) .. "!", "success", 8000)
            end)
    else
        -- Jika uang tidak cukup
        TriggerClientEvent('QBCore:Notify', src, "Uang Anda tidak cukup untuk membeli kendaraan ini.", "error", 8000)
    end
end)


-- ================================================================================
-- == EVENT AMAN UNTUK DEALER MENYETOK KENDARAAN (PENGGANTI px_vehicleshopBuyVehicle) ==
-- ================================================================================
RegisterServerEvent('px_vehicleshop:secureStockVehicle')
AddEventHandler('px_vehicleshop:secureStockVehicle', function(vehicleModel, action, r, g, b, job)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)

    if not xPlayer then return end

    -- Keamanan Tambahan: Periksa apakah pemain benar-benar memiliki pekerjaan dealer
    if xPlayer.PlayerData.job.name ~= job or job ~= "cardealer" then
        print(string.format("[PX-VEHICLESHOP EXPLOIT] Player %s (Job: %s) tried to stock vehicle as a %s.", xPlayer.PlayerData.name, xPlayer.PlayerData.job.name, job))
        return
    end

    -- 1. Validasi: Cari data kendaraan di config
    local vehicleData = GetVehicleData(vehicleModel)

    -- 2. Keamanan: Jika mobil tidak valid, hentikan
    if not vehicleData then
        print(string.format("[PX-VEHICLESHOP EXPLOIT] Dealer %s tried to stock an invalid vehicle model: %s", xPlayer.PlayerData.name, vehicleModel))
        return
    end

    -- 3. Sumber Kebenaran: Ambil harga dari CONFIG SERVER
    local correctPrice = tonumber(vehicleData.price)
    
    -- 4. Logika Bisnis: Lanjutkan proses pengurangan uang perusahaan & simpan ke JSON
    if Config.RemoveMoneyCompany then
        -- Gunakan API yang sesuai untuk mengambil uang dari society/company account
        -- Contoh: exports['qb-management']:RemoveMoney(job, correctPrice) atau yang sejenisnya
        -- Note: 'qb-banking' mungkin tidak punya fungsi untuk society, biasanya ada di qb-management atau framework job.
        -- Sesuaikan baris di bawah ini dengan sistem ekonomi Anda.
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