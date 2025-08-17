local stress = 0
local speedMultiplier = Config.UseMPH and 2.23694 or 3.6

RegisterNetEvent('hud:client:UpdateStress', function(newStress)
    if stress < newStress then
        lib.notify({
            title = 'STATUS',
            description = 'Kamu Merasa Agak Pusing',
            duration = 3500,
            position = 'top-right',
            type = 'info',
        })
    else
        lib.notify({
            title = 'STATUS',
            description = 'Kamu Merasa Relax',
            duration = 3500,
            position = 'top-right',
            type = 'success',
        })
    end
    stress = newStress
end)

-- Stress Gain

-- CreateThread(function() -- Speeding
--     while true do
--         if LocalPlayer.state.isLoggedIn then
--             local ped = cache.ped
--             if cache.vehicle then
--                 local veh = cache.vehicle
--                 local vehClass = GetVehicleClass(veh)
--                 local speed = GetEntitySpeed(veh) * speedMultiplier

--                 if vehClass ~= 13 and vehClass ~= 14 and vehClass ~= 15 and vehClass ~= 16 and vehClass ~= 21 then
--                     local stressSpeed = Config.MinimumSpeed
--                     if speed >= stressSpeed then
--                         TriggerServerEvent('hud:server:GainStress', 1)
--                     end
--                 end
--             end
--         end
--         Wait(20000)
--     end
-- end)

-- local function IsWhitelistedWeaponStress(weapon)
--     if weapon then
--         for _, v in pairs(Config.WhitelistedWeaponStress) do
--             if weapon == v then
--                 return true
--             end
--         end
--     end
--     return false
-- end

-- CreateThread(function() -- Shooting
--     local sleep = 1000
--     while true do
--         Wait(sleep)
--         sleep = 1000
--         if LocalPlayer.state.isLoggedIn then
--             local ped = cache.ped
--             local weapon = GetSelectedPedWeapon(ped)
--             if weapon ~= `WEAPON_UNARMED` then
--                 sleep = 5
--                 if IsPedShooting(ped) and not IsWhitelistedWeaponStress(weapon) then
--                     if math.random() < Config.StressChance then
--                         TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
--                     end
--                 end
--             end
--         end
--     end
-- end)

-- Stress Screen Effects

local function GetBlurIntensity(stresslevel)
    for _, v in pairs(Config.Intensity['blur']) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    for _, v in pairs(Config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.timeout
        end
    end
    return 60000
end

CreateThread(function()
    while true do
        local ped = cache.ped
        local effectInterval = GetEffectInterval(stress)
        if stress >= 100 then
            local BlurIntensity = GetBlurIntensity(stress)
            local FallRepeat = math.random(2, 4)
            local RagdollTimeout = FallRepeat * 1750
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)

            if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0)
            end

            Wait(1000)
            for _ = 1, FallRepeat, 1 do
                Wait(750)
                DoScreenFadeOut(200)
                Wait(1000)
                DoScreenFadeIn(200)
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
        elseif stress >= Config.MinimumStress then
            local BlurIntensity = GetBlurIntensity(stress)
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)
        end
        Wait(effectInterval)
    end
end)

RegisterCommand('stres', function (source, args, raw)
    print('add')
    TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
end)