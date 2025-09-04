local handlingOptions = {
    { name = "fMass", desc = "Berat kendaraan" },
    { name = "fInitialDragCoeff", desc = "Koefisien drag (udara)" },
    { name = "fPercentSubmerged", desc = "Persentase tenggelam air" },
    { name = "vecCentreOfMassOffset", desc = "Offset pusat massa (X,Y,Z)" },
    { name = "vecInertiaMultiplier", desc = "Inersia (rotasi body)" },
    { name = "fDriveBiasFront", desc = "Distribusi penggerak depan" },
    { name = "nInitialDriveGears", desc = "Jumlah gigi awal" },
    { name = "fInitialDriveForce", desc = "Kekuatan akselerasi" },
    { name = "fDriveInertia", desc = "Inersia penggerak" },
    { name = "fClutchChangeRateScaleUpShift", desc = "Kecepatan perpindahan gigi naik" },
    { name = "fClutchChangeRateScaleDownShift", desc = "Kecepatan perpindahan gigi turun" },
    { name = "fInitialDriveMaxFlatVel", desc = "Kecepatan maksimum kendaraan" },
    { name = "fBrakeForce", desc = "Kekuatan rem" },
    { name = "fBrakeBiasFront", desc = "Distribusi rem depan" },
    { name = "fHandBrakeForce", desc = "Kekuatan rem tangan" },
    { name = "fSteeringLock", desc = "Belokan steering (sudut maksimum)" },
    { name = "fTractionCurveMax", desc = "Traksi maksimum ban" },
    { name = "fTractionCurveMin", desc = "Traksi minimum ban" },
    { name = "fTractionCurveLateral", desc = "Gaya traksi lateral" },
    { name = "fTractionSpringDeltaMax", desc = "Perubahan traksi saat menikung" },
    { name = "fLowSpeedTractionLossMult", desc = "Traksi saat kecepatan rendah" },
    { name = "fCamberStiffnesss", desc = "Kekakuan sudut ban" },
    { name = "fTractionBiasFront", desc = "Distribusi traksi depan" },
    { name = "fTractionLossMult", desc = "Pengurangan traksi saat slip" },
    { name = "fSuspensionForce", desc = "Kekuatan suspensi" },
    { name = "fSuspensionCompDamp", desc = "Redam kompresi suspensi" },
    { name = "fSuspensionReboundDamp", desc = "Redam pantulan suspensi" },
    { name = "fSuspensionUpperLimit", desc = "Batas atas suspensi" },
    { name = "fSuspensionLowerLimit", desc = "Batas bawah suspensi" },
    { name = "fSuspensionRaise", desc = "Ketinggian suspensi" },
    { name = "fSuspensionBiasFront", desc = "Distribusi suspensi depan" },
    { name = "fAntiRollBarForce", desc = "Kekuatan anti-roll bar" },
    { name = "fAntiRollBarBiasFront", desc = "Distribusi anti-roll depan" },
    { name = "fRollCentreHeightFront", desc = "Tinggi pusat roll depan" },
    { name = "fRollCentreHeightRear", desc = "Tinggi pusat roll belakang" },
    { name = "fCollisionDamageMult", desc = "Multiplier kerusakan tabrakan" },
    { name = "fWeaponDamageMult", desc = "Multiplier kerusakan senjata" },
    { name = "fDeformationDamageMult", desc = "Multiplier deformasi body" },
    { name = "fEngineDamageMult", desc = "Multiplier kerusakan mesin" },
    { name = "fPetrolTankVolume", desc = "Kapasitas tangki bensin" },
    { name = "fOilVolume", desc = "Volume oli" },
    { name = "fSeatOffsetDistX", desc = "Offset kursi X" },
    { name = "fSeatOffsetDistY", desc = "Offset kursi Y" },
    { name = "fSeatOffsetDistZ", desc = "Offset kursi Z" },
    { name = "fMonetaryValue", desc = "Harga kendaraan" },
    { name = "strModelFlags", desc = "Flag model (string)" },
    { name = "strHandlingFlags", desc = "Flag handling (string)" },
    { name = "strDamageFlags", desc = "Flag damage (string)" },
    { name = "AIHandling", desc = "Mode AI Handling" }
}

RegisterNetEvent("lex_handling:client:openUI", function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle == 0 then
        ShowNotification("Kamu harus berada dalam kendaraan")
        return
    end

    local modelHash = GetEntityModel(vehicle)
    local spawnCode = GetDisplayNameFromVehicleModel(modelHash)

    if not spawnCode or spawnCode == "CARNOTFOUND" then
        spawnCode = tostring(modelHash)
    end

    local options = {}
    for _, opt in ipairs(handlingOptions) do
        local key = opt.name
        local valType = GetHandlingFieldType(key)
        local val = "?"
        if valType == "float" then
            val = GetVehicleHandlingFloat(vehicle, "CHandlingData", key)
        elseif valType == "int" then
            val = GetVehicleHandlingInt(vehicle, "CHandlingData", key)
        elseif valType == "vector" then
            local vec = GetVehicleHandlingVector(vehicle, "CHandlingData", key)
            val = string.format("%.6f,%.6f,%.6f", vec.x, vec.y, vec.z)
        end

        table.insert(options, {
            label = key,
            name = key,
            default = tostring(val),
            hint = opt.desc or ""
        })
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        options = options,
        vehiclename = spawnCode,
        spawnCode = spawnCode
    })
end)


RegisterCommand("edithandling", function()
    TriggerEvent('lex_handling:client:openUI')
end, false)

RegisterKeyMapping("edithandling", "Edit Handling Kendaraan (Admin Only)", "keyboard", "E")



RegisterNUICallback("submit", function(data, cb)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    for key, valStr in pairs(data) do
        local valType = GetHandlingFieldType(key)
        if valType == "float" then
            SetVehicleHandlingFloat(vehicle, "CHandlingData", key, tonumber(valStr))
        elseif valType == "int" then
            SetVehicleHandlingInt(vehicle, "CHandlingData", key, tonumber(valStr))
        elseif valType == "vector" then
            local x, y, z = valStr:match("([^,]+),([^,]+),([^,]+)")
            if x and y and z then
                local vec = vector3(tonumber(x), tonumber(y), tonumber(z))
                SetVehicleHandlingVector(vehicle, "CHandlingData", key, vec)
            end
        end
    end

    ShowNotification("Handling updated!")
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback("cancel", function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, true)
end

function GetHandlingFieldType(key)
    local floatFields = {
        fMass = true, fInitialDragCoeff = true, fPercentSubmerged = true,
        fDriveBiasFront = true, fInitialDriveForce = true, fDriveInertia = true,
        fClutchChangeRateScaleUpShift = true, fClutchChangeRateScaleDownShift = true,
        fInitialDriveMaxFlatVel = true, fBrakeForce = true, fBrakeBiasFront = true,
        fHandBrakeForce = true, fSteeringLock = true, fTractionCurveMax = true,
        fTractionCurveMin = true, fTractionCurveLateral = true, fTractionSpringDeltaMax = true,
        fLowSpeedTractionLossMult = true, fCamberStiffnesss = true, fTractionBiasFront = true,
        fTractionLossMult = true, fSuspensionForce = true, fSuspensionCompDamp = true,
        fSuspensionReboundDamp = true, fSuspensionUpperLimit = true, fSuspensionLowerLimit = true,
        fSuspensionRaise = true, fSuspensionBiasFront = true, fAntiRollBarForce = true,
        fAntiRollBarBiasFront = true, fRollCentreHeightFront = true, fRollCentreHeightRear = true,
        fCollisionDamageMult = true, fWeaponDamageMult = true, fDeformationDamageMult = true,
        fEngineDamageMult = true, fPetrolTankVolume = true, fOilVolume = true,
        fSeatOffsetDistX = true, fSeatOffsetDistY = true, fSeatOffsetDistZ = true,
        fMonetaryValue = true
    }

    local vectorFields = {
        vecCentreOfMassOffset = true, vecInertiaMultiplier = true
    }

    if floatFields[key] then return "float" end
    if vectorFields[key] then return "vector" end
    return "int"
end
