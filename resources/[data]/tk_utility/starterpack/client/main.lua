local RawConfig = require 'starterpack.shared.config'
local Cfg = RawConfig.Starterpack or RawConfig.Staterpack or RawConfig
local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    local m = Cfg.Target.ped.model
    local model = type(m) == 'string' and joaat(m) or m
    lib.requestModel(model, 1500)

    local p = Cfg.Target.ped
    local targetPed = CreatePed(4, model, p.coords.x, p.coords.y, p.coords.z - 1.0, p.heading or 0.0, false, true)
    SetEntityInvincible(targetPed, true)
    SetBlockingOfNonTemporaryEvents(targetPed, true)
    FreezeEntityPosition(targetPed, p.freeze ~= false)
    if p.scenario then TaskStartScenarioInPlace(targetPed, p.scenario, 0, true) end
    SetModelAsNoLongerNeeded(model)

    exports.ox_target:addLocalEntity(targetPed, {{
        label = Cfg.Target.label,
        icon = Cfg.Target.icon,
        onSelect = function() TriggerEvent('tk-stater:client:claim') end,
        distance = Cfg.Target.distance or 2.0
    }})
end)

local function spawnAndRegister(model, garage, state)
    local sp = Cfg.Vehicle.SpawnPoint
    local spawnCoords = (sp and vector4(sp.x, sp.y, sp.z, sp.w)) or (function()
        local ped = PlayerPedId()
        local c = GetEntityCoords(ped)
        local h = GetEntityHeading(ped)
        return vector4(c.x, c.y, c.z, h)
    end)

    local plate = exports.vehicleshop:GeneratePlate()

    QBCore.Functions.SpawnVehicle(model, function(veh)
        SetVehicleNumberPlateText(veh, plate)
        SetEntityHeading(veh, spawnCoords.w)
        SetVehicleOnGroundProperly(veh)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        exports['cdn-fuel']:SetFuel(veh, 100)

        TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(veh))
        TriggerServerEvent('tk-stater:server:register', model, plate, garage, state)

        lib.notify({
            title = 'Starter Pack',
            description = ('Kendaraan siap. Model: %s | Plate: %s'):format(model, plate),
            type = 'info',
            position = 'top-right'
        })
    end, spawnCoords, true)
end

RegisterNetEvent('tk-stater:client:claim', function()
    local result = lib.alertDialog({
        header = Cfg.Rules.header,
        content = Cfg.Rules.text,
        centered = true,
        cancel = true,
        labels = { confirm = Cfg.Rules.button.submit, cancel = Cfg.Rules.button.cancel }
    })
    if result ~= 'confirm' then
        lib.notify({ title = 'Starter Pack', description = 'Dibatalkan.', type = 'error', position = 'top-right' })
        return
    end

    local ok, resp = pcall(function()
        return lib.callback.await('tk-stater:server:claim', false)
    end)

    if not ok or not resp then
        lib.notify({ title = 'Starter Pack', description = 'Terjadi kesalahan.', type = 'error', position = 'top-right' })
        return
    end

    if not resp.ok then
        lib.notify({ title = 'Starter Pack', description = resp.msg or 'Gagal claim.', type = 'error', position = 'top-right' })
        return
    end

    lib.notify({ title = 'Starter Pack', description = resp.msg or 'Berhasil!', type = 'success', position = 'top-right' })

    local v = resp.vehicle
    if v and v.spawn then
        spawnAndRegister(v.model, v.garage, v.state)
    end
end)