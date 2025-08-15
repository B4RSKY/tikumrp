local QBCore = exports['qb-core']:GetCoreObject()
local loop = exports.tk_modul:getLoop()

local finishMarker, busVehicle, finishBlip = nil, nil, nil
local currentRouteIndex = 1
local currentRoute = nil
local pedCoords = {}
local pedDuty, isWorking, isInShopMenu = false, false, false
local LastTerminal, LastPart, LastPartNum, CurrentAction
local currentRouteKey = nil
local totalSalaryEarned = 0
local isTextUIShowing = false
local lastUpdateTime = 0
local outOfVehicleTime = 0
local isOutOfVehicleTimer = false
local idleStartTime = 0
local IDLE_TIMEOUT = 1800 -- 30 menit dalam detik (30 * 60)

CreateThread(function()
    loop.create('loop_bus_job', function()
        if pedDuty and not isWorking and idleStartTime > 0 then
            local elapsedTime = (GetGameTimer() - idleStartTime) / 1000
            if elapsedTime > IDLE_TIMEOUT then
                ResetDuty()
                return
            end
        end

        pedCoords = GetEntityCoords(PlayerPedId())

        if isWorking then
            TransitBus()
            VehicleCheck()
        else
            FinalMarkBus()
        end
    end, 200)
end)

function VehicleCheck()
    if not busVehicle then return end
    
    local playerPed = PlayerPedId()
    local currentVehicle = GetVehiclePedIsIn(playerPed, false)
    
    if currentVehicle ~= busVehicle then
        if not isOutOfVehicleTimer then
            isOutOfVehicleTimer = true
            outOfVehicleTime = GetGameTimer()
            QBCore.Functions.Notify("DISNAKER", "⚠️ Anda keluar dari bus! Kembali dalam 30 detik atau pekerjaan akan direset!", "warning", 5000)
        else
            local timeDiff = (GetGameTimer() - outOfVehicleTime) / 1000
            if timeDiff >= 30 then
                QBCore.Functions.Notify("DISNAKER", "Bus dikembalikan karena Anda terlalu lama keluar!", "error", 5000)
                ForceResetWork()
                isOutOfVehicleTimer = false
            elseif timeDiff >= 25 then
                QBCore.Functions.Notify("DISNAKER", string.format("⏰ %d detik lagi bus akan dikembalikan!", 30 - math.floor(timeDiff)), "warning", 2000)
            end
        end
    else
        if isOutOfVehicleTimer then
            isOutOfVehicleTimer = false
            QBCore.Functions.Notify("DISNAKER", "Anda kembali ke bus!", "success", 2000)
        end
    end
end

FinalMarkBus = function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local isInMarker, hasExited = false, false
    local currentStation, currentPart, currentPartNum

    for k, v in pairs(Config.Bus) do
        for i = 1, #v.spawn_bus, 1 do
            local distance = #(playerCoords - vector3(v.spawn_bus[i].x, v.spawn_bus[i].y, v.spawn_bus[i].z))
            
            if distance < 4.0 and pedDuty and not isWorking then
                if not isTextUIShowing then
                    isTextUIShowing = true
                    lib.showTextUI('[E] - Selesai Kerja', {
                        position = "left-center",
                        icon = "fa-solid fa-square-check"
                    })
                end
                isInMarker, currentStation, currentPart, currentPartNum = true, k, 'TerminalBus', i
            end
        end
    end

    if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastTerminal ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
        if (LastTerminal and LastPart and LastPartNum) and (LastTerminal ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum) then
            TriggerEvent('tk-disnaker:bus:exitMarker', LastTerminal, LastPart, LastPartNum)
            hasExited = true
        end

        HasAlreadyEnteredMarker = true
        LastTerminal = currentStation
        LastPart = currentPart
        LastPartNum = currentPartNum
        TriggerEvent('tk-disnaker:bus:inMarker', currentStation, currentPart, currentPartNum)
    end

    if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
        if isTextUIShowing then
            isTextUIShowing = false
            lib.hideTextUI()
        end
        HasAlreadyEnteredMarker = false
        TriggerEvent('tk-disnaker:bus:exitMarker', LastTerminal, LastPart, LastPartNum)
    end
end

AddEventHandler('tk-disnaker:bus:inMarker', function(station, part, partNum)
    if part == 'TerminalBus' then
        CurrentAction = 'terminal_bus'
    end
end)

AddEventHandler('tk-disnaker:bus:exitMarker', function(station, part, partNum)
    if not isInShopMenu then
        lib.hideContext()
    end
    CurrentAction = nil
end)

local keybind = lib.addKeybind({
    name = 'job_bus_finish',
    description = 'Action Bus Job',
    defaultKey = 'E',
    onPressed = function(self)
        local ped = PlayerPedId()
        if CurrentAction ~= nil and IsPedInSpawnBus() and not IsPlayerDead(ped) then
            if CurrentAction == 'terminal_bus' and pedDuty and not isWorking then
                if lib.progressBar({
                    duration = 5000,
                    label = 'Mengembalikan Bus',
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        move = true,
                        car = true,
                        combat = true,
                        mouse = false
                    },
                }) then 
                    FinishWork()
                end
            end
        end
        CurrentAction = nil
    end,
})

exports.ox_target:addBoxZone({
    coords = Config.DutyBus,
    size = vec3(3,3,3),
    rotation = 3,
    options = {
        {
            event = 'tk-disnaker:bus:ShowClothingMenu',
            icon = 'fas fa-tshirt',
            label = 'Ganti Pakaian',
        },
        {
            event = 'tk-disnaker:bus:ShowRouteMenu',
            icon = 'fa-solid fa-bus',
            label = 'Pilih Rute',
            canInteract = function(entity)
                return CheckDuty() == true and not isWorking
            end
        },
    }
})

RegisterNetEvent('tk-disnaker:bus:ShowClothingMenu', function()
    lib.registerContext({
        id = 'clothing_menu',
        title = 'Supir Bus',
        options = {
            {
                title = 'Pakaian Dinas',
                description = 'Untuk Bekerja',
                icon = 'fa-solid fa-shirt',
                onSelect = function()
                    if lib.progressBar({
                        duration = 4000,
                        label = 'Mengganti Pakaian',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            car = true,
                            combat = true,
                            mouse = false
                        },
                        anim = {
                            dict = 'clothingtie',
                            clip = 'try_tie_positive_a',
                            flags = 49,
                        },
                    }) then 
                        if CheckDuty() then
                            QBCore.Functions.Notify("DISNAKER", "Ambil bus untuk mulai bekerja", "info", 3000)
                        else
                            pedDuty = true
                            JobSetUniform()
                            QBCore.Functions.Notify("DISNAKER", "Anda sekarang sedang bertugas", "success", 3000)
                        end
                    end
                end
            },
            {
                title = 'Pakaian Biasa',
                description = 'Untuk Istirahat',
                icon = 'fa-solid fa-user',
                onSelect = function()
                    if lib.progressBar({
                        duration = 4000,
                        label = 'Mengganti Pakaian',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            car = true,
                            combat = true,
                            mouse = false
                        },
                        anim = {
                            dict = 'clothingtie',
                            clip = 'try_tie_positive_a',
                            flags = 49,
                        },
                    }) then 
                        if not CheckDuty() then
                            QBCore.Functions.Notify("DISNAKER", "Anda sedang off duty", "info", 3000)
                        else
                            if isWorking then
                                QBCore.Functions.Notify("DISNAKER", "Selesaikan pekerjaan terlebih dahulu!", "error", 3000)
                                return
                            end
                            ResetDuty()
                            TriggerServerEvent('qb-clothing:loadPlayerSkin')
                            QBCore.Functions.Notify("DISNAKER", "Anda sekarang off duty", "success", 3000)
                        end
                    end
                end
            }
        },
    })
    lib.showContext('clothing_menu')
end)

RegisterNetEvent('tk-disnaker:bus:ShowRouteMenu', function()
    local options = {}
    
    for routeKey, routeData in pairs(Config.Bus) do
        table.insert(options, {
            title = routeData.label_rute,
            description = 'Total Pendapatan: TK$' .. routeData.total_pendapatan .. ' | Total Stop: ' .. #routeData.rute,
            icon = 'fa-solid fa-bus',
            onSelect = function()
                StartBusRoute(routeKey)
            end
        })
    end
    
    lib.registerContext({
        id = 'route_menu',
        title = 'Pilih Rute Bus',
        options = options,
    })
    lib.showContext('route_menu')
end)

TransitBus = function()
    if finishMarker and currentRoute and currentRoute.rute[currentRouteIndex] then
        local targetLocation = currentRoute.rute[currentRouteIndex]
        DrawMarker(22, targetLocation.coords.x, targetLocation.coords.y, targetLocation.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 180.0, 2.0, 2.0, 2.0, 255, 255, 0, 200, true, false, 2, true, nil, nil, false)
        
        local distance = #(vector3(targetLocation.coords.x, targetLocation.coords.y, targetLocation.coords.z) - pedCoords)
        
        if distance < 5.0 and IsControlPressed(0, 38) and IsPedInSpawnBus() then
            if lib.progressBar({
                duration = 2000,
                label = "Menurunkan Penumpang di " .. targetLocation.nama,
                useWhileDead = false,
                canCancel = false,
                disable = {
                    move = true,
                    car = true,
                    combat = true,
                    mouse = false
                },
            }) then 
                if currentRouteIndex >= #currentRoute.rute then
                    CompleteRoute()
                else
                    NextCheckpoint()
                end
            end
        end
    end
end

function StartBusRoute(routeKey)
    if lib.progressBar({
        duration = 3000,
        label = 'Mengeluarkan Bus',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
    }) then 
        currentRouteKey = routeKey
        currentRoute = Config.Bus[routeKey]
        SpawnBus()
    end
end

function SpawnBus()
    if not IsPedInBus() and not busVehicle then
        local spawnCoord = currentRoute.spawn_bus[1]
        local busModel = currentRoute.bus_model or Config.DefaultBusHash
        
        QBCore.Functions.SpawnVehicle(busModel, function(vehicle)
            if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
                Wait(200)
                busVehicle = vehicle
                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                exports["cdn-fuel"]:SetFuel(vehicle, 100.0)
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(vehicle))
                
                isWorking = true
                currentRouteIndex = 1
                totalSalaryEarned = 0
                StartRoute()
            end
        end, spawnCoord, true)
    end
end

function StartRoute()
    idleStartTime = 0
    finishMarker = true
    isWorking = true
    UpdateRouteBlip()
    UpdateTextUI()
    QBCore.Functions.Notify("DISNAKER", "Silahkan lanjut ke checkpoint pertama!", "success", 3000)
end

function NextCheckpoint()
    if DoesBlipExist(finishBlip) then
        RemoveBlip(finishBlip)
    end
    
    currentRouteIndex = currentRouteIndex + 1
    
    local paymentPerCheckpoint = math.floor(currentRoute.total_pendapatan / #currentRoute.rute)
    totalSalaryEarned = totalSalaryEarned + paymentPerCheckpoint
    
    UpdateRouteBlip()
    UpdateTextUI()
    disnaker('cp', 'sbus', nil, paymentPerCheckpoint)
    QBCore.Functions.Notify("Checkpoint selesai! +TK$" .. paymentPerCheckpoint, "success", 2000)
end

function CompleteRoute()
    if DoesBlipExist(finishBlip) then
        RemoveBlip(finishBlip)
    end
    
    local remainingPayment = currentRoute.total_pendapatan - totalSalaryEarned
    if remainingPayment > 0 then
        totalSalaryEarned = totalSalaryEarned + remainingPayment
    end
    
    finishMarker = nil
    isWorking = false
    HideRouteTextUI()
    idleStartTime = GetGameTimer()
    SetNewWaypoint(-820.43, 1745.5)
    QBCore.Functions.Notify("DISNAKER", "Rute selesai! Kembali ke terminal untuk mengembalikan bus", "success", 5000)
end

function FinishWork()
    DeleteBus()
    currentRouteIndex = 1
    currentRoute = nil
    currentRouteKey = nil
    finishMarker = nil
    isWorking = false
    isOutOfVehicleTimer = false
    HideRouteTextUI()
    disnaker('final', 'sbus', nil, totalSalaryEarned)
    QBCore.Functions.Notify("DISNAKER", "Pekerjaan selesai! Total pendapatan: TK$" .. totalSalaryEarned, "success", 5000)
    totalSalaryEarned = 0
end

function ForceResetWork()
    DeleteBus()
    currentRouteIndex = 1
    currentRoute = nil
    currentRouteKey = nil
    finishMarker = nil
    isWorking = false
    isOutOfVehicleTimer = false
    HideRouteTextUI()
    totalSalaryEarned = 0
    
    if DoesBlipExist(finishBlip) then
        RemoveBlip(finishBlip)
    end
end

function UpdateTextUI()
    if currentRoute and currentRoute.rute[currentRouteIndex] then
        local currentTime = GetGameTimer()
        
        if currentTime - lastUpdateTime > 2000 or lastUpdateTime == 0 then
            local nextDestination = currentRoute.rute[currentRouteIndex].nama
            local remainingStops = #currentRoute.rute - currentRouteIndex + 1
            local uiText = string.format(
                "🚌 **Tujuan:** %s  \n💰 **Gaji:** TK$%d  \n📍 **Sisa Rute:** %d/%d",
                nextDestination,
                totalSalaryEarned,
                remainingStops,
                #currentRoute.rute
            )
            
            lib.showTextUI(uiText, {
                position = "left-center",
                icon = "fa-solid fa-bus",
            })
            isTextUIShowing = true
            lastUpdateTime = currentTime
        end
    end
end

function HideRouteTextUI()
    if isTextUIShowing then
        lib.hideTextUI()
        isTextUIShowing = false
    end
end

function UpdateRouteBlip()
    if currentRoute and currentRoute.rute[currentRouteIndex] then
        local targetLocation = currentRoute.rute[currentRouteIndex]
        
        finishBlip = AddBlipForCoord(targetLocation.coords.x, targetLocation.coords.y, targetLocation.coords.z)
        SetBlipSprite(finishBlip, 538)
        SetBlipDisplay(finishBlip, 4)
        SetBlipScale(finishBlip, 0.9)
        SetBlipColour(finishBlip, 5)
        SetBlipAsShortRange(finishBlip, 0)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Rute Bus | ' .. targetLocation.nama)
        EndTextCommandSetBlipName(finishBlip)
        SetNewWaypoint(targetLocation.coords.x, targetLocation.coords.y)
    end
end

function CheckDuty()
    return pedDuty
end

function JobSetUniform()
    TriggerEvent('qb-clothing:client:loadPlayerClothing', Config.JobUniforms)
    pedDuty = true
    idleStartTime = GetGameTimer()
    loop.start('loop_bus_job')
end

function IsPedInSpawnBus()
    return (GetVehiclePedIsIn(PlayerPedId(), false) == busVehicle)
end

function IsPedInBus()
    return (GetVehiclePedIsIn(PlayerPedId(), false) ~= 0)
end

function DeleteBus()
    if DoesEntityExist(busVehicle) and IsEntityAVehicle(busVehicle) then
        DeleteEntity(busVehicle)
        busVehicle = nil
    end
end

function ResetDuty()
    loop.stop('loop_bus_job')
    idleStartTime = 0
    DeleteBus()
    if DoesBlipExist(finishBlip) then
        RemoveBlip(finishBlip)
    end
    pedDuty = false
    isWorking = false
    isOutOfVehicleTimer = false
    finishMarker = nil
    currentRoute = nil
    currentRouteKey = nil
    currentRouteIndex = 1
    totalSalaryEarned = 0
    lastUpdateTime = 0
    HideRouteTextUI()
end