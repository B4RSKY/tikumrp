local PlayerJob = {}
local onDuty = false
local currentHospital
local lib1_char_a, lib2_char_a, lib1_char_b, lib2_char_b, anim_start, anim_pump, anim_success = 'mini@cpr@char_a@cpr_def', 'mini@cpr@char_a@cpr_str', 'mini@cpr@char_b@cpr_def', 'mini@cpr@char_b@cpr_str', 'cpr_intro', 'cpr_pumpchest', 'cpr_success'
local cpr = false

CreateThread(function()
    RequestAnimDict(lib1_char_a)
    RequestAnimDict(lib2_char_a)
    RequestAnimDict(lib1_char_b)
    RequestAnimDict(lib2_char_b)
end)

RegisterNetEvent('tk_ambulance:playCPR')
AddEventHandler('tk_ambulance:playCPR', function(playerheading, playercoords, playerlocation)
    local playerPed = cache.ped
    cpr = true

    ClampGameplayCamPitch(0.0, -90.0)
    local x, y, z = table.unpack(playercoords + playerlocation)
    NetworkResurrectLocalPlayer(x, y, z, playerheading, true, false)

    ClearPedTasksImmediately(playerPed)
    TriggerEvent('hospital:client:SetDead', false)
    TriggerServerEvent('hospital:server:SetDeathStatus', false)

    SetEntityHeading(playerPed, playerheading - 270.0)

    TaskPlayAnim(playerPed, lib1_char_b, anim_start, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(15800 - 900)
    for i=1, 15, 1 do
        Wait(900)
        TaskPlayAnim(playerPed, lib2_char_b, anim_pump, 8.0, 8.0, -1, 0, 0, false, false, false)
    end

    cpr = false
    ClearPedTasks(playerPed)
    TaskPlayAnim(playerPed, lib2_char_b, anim_success, 8.0, 8.0, -1, 0, 0, false, false, false)
end)



-- Functions

local function GetClosestPlayer()
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())

    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

-- Events
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    if PlayerJob.name == 'ambulance' then
        onDuty = PlayerJob.onduty
        if PlayerJob.onduty then
            TriggerServerEvent('hospital:server:AddDoctor', PlayerJob.name)
        else
            TriggerServerEvent('hospital:server:RemoveDoctor', PlayerJob.name)
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports.spawnmanager:setAutoSpawn(false)
    local ped = PlayerPedId()
    local player = PlayerId()
    CreateThread(function()
        Wait(5000)
        SetEntityMaxHealth(ped, 200)
        SetEntityHealth(ped, 200)
        SetPlayerHealthRechargeMultiplier(player, 0.0)
        SetPlayerHealthRechargeLimit(player, 0.0)
    end)
    CreateThread(function()
        Wait(1000)
        QBCore.Functions.GetPlayerData(function(PlayerData)
            PlayerJob = PlayerData.job
            onDuty = PlayerData.job.onduty
            SetPedArmour(PlayerPedId(), PlayerData.metadata['armor'])
            if (not PlayerData.metadata['inlaststand'] and PlayerData.metadata['isdead']) then
                deathTime = Config.ReviveInterval
                OnDeath()
                DeathTimer()
            elseif (PlayerData.metadata['inlaststand'] and not PlayerData.metadata['isdead']) then
                SetLaststand(true)
            else
                TriggerServerEvent('hospital:server:SetDeathStatus', false)
                TriggerServerEvent('hospital:server:SetLaststandStatus', false)
            end
            if PlayerJob.name == 'ambulance' and onDuty then
                TriggerServerEvent('hospital:server:AddDoctor', PlayerJob.name)
            end
        end)
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if PlayerJob.name == 'ambulance' and onDuty then
        TriggerServerEvent('hospital:server:RemoveDoctor', PlayerJob.name)
    end
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    if PlayerJob.name == 'ambulance' and duty ~= onDuty then
        if duty then
            TriggerServerEvent('hospital:server:AddDoctor', PlayerJob.name)
        else
            TriggerServerEvent('hospital:server:RemoveDoctor', PlayerJob.name)
        end
    end

    onDuty = duty
end)

function Status()
    if isStatusChecking then
        local statusMenu = {
            {
                header = Lang:t('menu.status'),
                isMenuHeader = true
            }
        }
        for _, v in pairs(statusChecks) do
            statusMenu[#statusMenu + 1] = {
                header = v.label,
                txt = '',
                params = {
                    event = 'hospital:client:TreatWounds',
                }
            }
        end
        statusMenu[#statusMenu + 1] = {
            header = Lang:t('menu.close'),
            txt = '',
            params = {
                event = 'qb-menu:client:closeMenu'
            }
        }
        exports['qb-menu']:openMenu(statusMenu)
    end
end

RegisterNetEvent('hospital:client:CheckStatus', function()
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 5.0 then
        local playerId = GetPlayerServerId(player)
        QBCore.Functions.TriggerCallback('hospital:GetPlayerStatus', function(result)
            if result then
                for k, v in pairs(result) do
                    if k ~= 'BLEED' and k ~= 'WEAPONWOUNDS' then
                        statusChecks[#statusChecks + 1] = {
                            bone = Config.BoneIndexes[k],
                            label = v.label .. ' (' .. Config.WoundStates[v.severity] .. ')'
                        }
                    elseif result['WEAPONWOUNDS'] then
                        for _, v2 in pairs(result['WEAPONWOUNDS']) do
                            TriggerEvent('chat:addMessage', {
                                color = { 255, 0, 0 },
                                multiline = false,
                                args = { Lang:t('info.status'), QBCore.Shared.Weapons[v2].damagereason }
                            })
                        end
                    elseif result['BLEED'] > 0 then
                        TriggerEvent('chat:addMessage', {
                            color = { 255, 0, 0 },
                            multiline = false,
                            args = { Lang:t('info.status'),
                                Lang:t('info.is_status', { status = Config.BleedingStates[v].label }) }
                        })
                    else
                        QBCore.Functions.Notify(Lang:t('success.healthy_player'), 'success')
                    end
                end
                isStatusChecking = true
                Status()
            end
        end, playerId)
    else
        QBCore.Functions.Notify(Lang:t('error.no_player'), 'error')
    end
end)

RegisterNetEvent('hospital:client:RevivePlayer', function()
    local hasItem = exports['qb-core']:HasItem('firstaid', 1)
    if hasItem then
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 5.0 then
            local playerId = GetPlayerServerId(player)
            local playerPed = cache.ped
            ExecuteCommand('me Memberikan Pertolongan')
            ClearPedTasksImmediately(player)
            TriggerServerEvent('tk_ambulance:requestCPR', GetPlayerServerId(player), GetEntityHeading(playerPed), GetEntityCoords(playerPed), GetEntityForwardVector(playerPed))
            cpr = true
            TaskPlayAnim(playerPed, lib1_char_a, anim_start, 8.0, 8.0, -1, 0, 0, false, false, false)
            Wait(15800 - 900)
            for i=1, 15, 1 do
                Wait(900)
                TaskPlayAnim(playerPed, lib2_char_a, anim_pump, 8.0, 8.0, -1, 0, 0, false, false, false)
            end
            cpr = false
            TaskPlayAnim(playerPed, lib2_char_a, anim_success, 8.0, 8.0, -1, 0, 0, false, false, false)
            Wait(33590)
            QBCore.Functions.Notify(Lang:t('success.revived'), 'success')
            TriggerServerEvent('hospital:server:RevivePlayer', playerId)
        else
            QBCore.Functions.Notify(Lang:t('error.no_player'), 'error')
        end
    else
        QBCore.Functions.Notify(Lang:t('error.no_firstaid'), 'error')
    end
end)

RegisterNetEvent('hospital:client:TreatWounds', function()
    local hasItem = exports['qb-core']:HasItem('bandage', 1)
    if hasItem then
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 5.0 then
            local playerId = GetPlayerServerId(player)
            if lib.progressBar({
                duration = 5000,
                label = Lang:t('progress.healing'),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    combat = true,
                    mouse = false
                },
                anim = { dict = healAnimDict, clip = healAnim},
            }) then 
                QBCore.Functions.Notify(Lang:t('success.helped_player'), 'success')
                TriggerServerEvent('hospital:server:TreatWounds', playerId)
            else
                QBCore.Functions.Notify(Lang:t('error.canceled'), 'error')
            end
        else
            QBCore.Functions.Notify(Lang:t('error.no_player'), 'error')
        end
    else
        QBCore.Functions.Notify(Lang:t('error.no_bandage'), 'error')
    end
end)

local check = false
local function EMSControls(variable)
    CreateThread(function()
        check = true
        while check do
            if IsControlJustPressed(0, 38) then
                exports['qb-core']:KeyPressed(38)
                if variable == 'sign' then
                    TriggerEvent('EMSToggle:Duty')
                elseif variable == 'roof' then
                    TriggerEvent('qb-ambulancejob:elevator_main')
                elseif variable == 'main' then
                    TriggerEvent('qb-ambulancejob:elevator_roof')
                end
            end
            Wait(1)
        end
    end)
end

RegisterNetEvent('qb-ambulancejob:elevator_roof', function()
    local ped = PlayerPedId()
    for i = 1, #Config.Locations['roof'] do
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(10) end
        currentHospital = i
        local coords = Config.Locations['main'][currentHospital]
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, coords.w)
        Wait(100)
        DoScreenFadeIn(1000)
    end
end)

RegisterNetEvent('qb-ambulancejob:elevator_main', function()
    local ped = PlayerPedId()
    for i = 1, #Config.Locations['main'] do
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(10) end
        currentHospital = i
        local coords = Config.Locations['roof'][currentHospital]
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, coords.w)
        Wait(100)
        DoScreenFadeIn(1000)
    end
end)

RegisterNetEvent('EMSToggle:Duty', function()
    onDuty = not onDuty
    TriggerServerEvent('QBCore:ToggleDuty')
    TriggerServerEvent('police:server:UpdateBlips')
end)
-- Convar turns into a boolean
if Config.UseTarget then
    CreateThread(function()
        for i = 1, #Config.Locations['duty'] do
            local v = Config.Locations['duty'][i]
            exports['qb-target']:AddBoxZone('duty' .. i, vector3(v.x, v.y, v.z), 1.5, 1, {
                name = 'duty' .. i,
                debugPoly = false,
                heading = -20,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            }, {
                options = {
                    {
                        type = 'client',
                        event = 'EMSToggle:Duty',
                        icon = 'fa fa-clipboard',
                        label = 'Sign In/Off duty',
                        job = 'ambulance'
                    }
                },
                distance = 1.5
            })
        end

        for i = 1, #Config.Locations['roof'] do
            local v = Config.Locations['roof'][i]
            exports['qb-target']:AddBoxZone('roof' .. i, vector3(v.x, v.y, v.z), 2, 2, {
                name = 'roof' .. i,
                debugPoly = false,
                heading = -20,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            }, {
                options = {
                    {
                        type = 'client',
                        event = 'qb-ambulancejob:elevator_roof',
                        icon = 'fas fa-hand-point-up',
                        label = 'Take Elevator',
                        job = 'ambulance'
                    },
                },
                distance = 8
            })
        end
        for i = 1, #Config.Locations['main'] do
            local v = Config.Locations['main'][i]
            exports['qb-target']:AddBoxZone('main' .. i, vector3(v.x, v.y, v.z), 1.5, 1.5, {
                name = 'main' .. i,
                debugPoly = false,
                heading = -20,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            }, {
                options = {
                    {
                        type = 'client',
                        event = 'qb-ambulancejob:elevator_main',
                        icon = 'fas fa-hand-point-up',
                        label = 'Take Elevator',
                        job = 'ambulance'
                    },
                },
                distance = 8
            })
        end
    end)
else
    CreateThread(function()
        local signPoly = {}
        for i = 1, #Config.Locations['duty'] do
            local v = Config.Locations['duty'][i]
            signPoly[#signPoly + 1] = BoxZone:Create(vector3(v.x, v.y, v.z), 1.5, 1, {
                name = 'sign' .. i,
                debugPoly = false,
                heading = -20,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            })
        end

        local signCombo = ComboZone:Create(signPoly, { name = 'signcombo', debugPoly = false })
        signCombo:onPlayerInOut(function(isPointInside)
            if isPointInside and PlayerJob.name == 'ambulance' then
                if not onDuty then
                    exports['qb-core']:DrawText(Lang:t('text.onduty_button'), 'left')
                    EMSControls('sign')
                else
                    exports['qb-core']:DrawText(Lang:t('text.offduty_button'), 'left')
                    EMSControls('sign')
                end
            else
                check = false
                exports['qb-core']:HideText()
            end
        end)

        local roofPoly = {}
        for i = 1, #Config.Locations['roof'] do
            local v = Config.Locations['roof'][i]
            roofPoly[#roofPoly + 1] = BoxZone:Create(vector3(v.x, v.y, v.z), 2, 2, {
                name = 'roof' .. i,
                debugPoly = false,
                heading = 70,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            })
        end

        local roofCombo = ComboZone:Create(roofPoly, { name = 'roofCombo', debugPoly = false })
        roofCombo:onPlayerInOut(function(isPointInside)
            if isPointInside and PlayerJob.name == 'ambulance' then
                if onDuty then
                    exports['qb-core']:DrawText(Lang:t('text.elevator_main'), 'left')
                    EMSControls('main')
                else
                    exports['qb-core']:DrawText(Lang:t('error.not_ems'), 'left')
                end
            else
                check = false
                exports['qb-core']:HideText()
            end
        end)

        local mainPoly = {}
        for i = 1, #Config.Locations['main'] do
            local v = Config.Locations['main'][i]
            mainPoly[#mainPoly + 1] = BoxZone:Create(vector3(v.x, v.y, v.z), 1.5, 1.5, {
                name = 'main' .. i,
                debugPoly = false,
                heading = 70,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            })
        end

        local mainCombo = ComboZone:Create(mainPoly, { name = 'mainPoly', debugPoly = false })
        mainCombo:onPlayerInOut(function(isPointInside)
            if isPointInside and PlayerJob.name == 'ambulance' then
                if onDuty then
                    exports['qb-core']:DrawText(Lang:t('text.elevator_roof'), 'left')
                    EMSControls('roof')
                else
                    exports['qb-core']:DrawText(Lang:t('error.not_ems'), 'left')
                end
            else
                check = false
                exports['qb-core']:HideText()
            end
        end)
    end)
end
