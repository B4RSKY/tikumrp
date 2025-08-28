local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('tackle:server:TacklePlayer', function(playerId)
    TriggerClientEvent('tackle:client:GetTackled', playerId)
end)

QBCore.Commands.Add('id', 'Check Your ID #', {}, false, function(source)
    TriggerClientEvent('QBCore:Notify', source, 'ID: ' .. source)
end)

RegisterNetEvent('qb-carwash:server:washCar', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if Player.Functions.RemoveMoney('cash', Config.CarWash.defaultPrice, 'car-washed') then
        TriggerClientEvent('qb-carwash:client:washCar', src)
    elseif Player.Functions.RemoveMoney('bank', Config.CarWash.defaultPrice, 'car-washed') then
        TriggerClientEvent('qb-carwash:client:washCar', src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.dont_have_enough_money'), 'error')
    end
end)

QBCore.Functions.CreateCallback('smallresources:server:GetCurrentPlayers', function(_, cb)
    cb(#GetPlayers())
end)

--Uang tidak bisa di masukkan trunk dsb
local hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
    return payload.toType == 'player' and payload.fromType == 'player'
end, {
    print = false,
    itemFilter = {money = true},
})

RegisterCommand('cekvipsv', function(src, args, raw)
    if src <= 0 then
        print('[tk_vip] Jalankan in-game, bukan dari console.')
        return
    end

    -- Pastikan nama resource yang punya export benar
    local ok = exports.tk_vip:getVip(src)   -- ganti tk_modul sesuai NAMA FOLDER resource VIP kamu
    print(('[tk_vip] cekvipsv src=%s getVip=%s'):format(src, tostring(ok)))

    if ok then
        print('OKE Saya VIP')
    else
        print('Ga VIP')
    end
end, false)
