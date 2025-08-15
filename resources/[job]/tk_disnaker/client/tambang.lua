local QBCore = exports['qb-core']:GetCoreObject()

local sibukMining = false
local cucibatu = Lokasi.Miner.cuciBatu
local tb = {ss = TriggerServerEvent}
local rocksSpawned = {}
local rockModels = {
    'prop_rock_1_a',
    'prop_rock_1_b',
    'prop_rock_1_c',
    'prop_rock_1_d',
    'prop_rock_1_e'
}

-- Auto Mining Variables
local autoMining = {
    active = false,
    startTime = 0,
    maxDuration = 10 * 60 * 1000, -- 10 menit dalam milliseconds
    cooldown = 5 * 60 * 1000, -- 5 menit cooldown
    lastUsed = 0, -- Set to 0 agar pertama kali tidak ada cooldown
    thread = nil,
    timerThread = nil
}

local miningZone = lib.points.new({
    coords = vector3(2948.69, 2792.83, 40.71),
    distance = 50,
})

-- Optimasi: Cache untuk menghindari kalkulasi berulang
local cachedGroundZ = {}

local function getRandomPositionInZone(centerCoords, maxDistance)
    local attempts = 0
    local maxAttempts = 10
    
    while attempts < maxAttempts do
        local randomAngle = math.random() * 2 * math.pi
        local randomRadius = math.random() * maxDistance
        
        local offsetX = math.cos(randomAngle) * randomRadius
        local offsetY = math.sin(randomAngle) * randomRadius
        
        local x = centerCoords.x + offsetX
        local y = centerCoords.y + offsetY

        local cacheKey = string.format("%.1f_%.1f", x, y)
        
        if cachedGroundZ[cacheKey] then
            return vector3(x, y, cachedGroundZ[cacheKey])
        end
        
        local testHeights = {centerCoords.z + 50.0, centerCoords.z + 100.0, centerCoords.z + 20.0}
        
        for _, testHeight in ipairs(testHeights) do
            local ground, z = GetGroundZFor_3dCoord(x, y, testHeight, 0)
            
            if ground and z then
                if math.abs(z - centerCoords.z) <= 20.0 then
                    cachedGroundZ[cacheKey] = z
                    return vector3(x, y, z)
                end
            end
        end
        
        attempts = attempts + 1
    end

    return vector3(
        centerCoords.x + math.random(-5, 5),
        centerCoords.y + math.random(-5, 5),
        centerCoords.z
    )
end

local function findNearestRock(playerCoords)
    local nearestRock = nil
    local nearestDistance = math.huge
    
    for rockId, rockData in pairs(rocksSpawned) do
        if DoesEntityExist(rockData.entity) then
            local distance = #(playerCoords - rockData.coords)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestRock = {id = rockId, data = rockData, distance = distance}
                
                if distance < 5.0 then
                    break
                end
            end
        end
    end
    
    return nearestRock
end

local function walkToTarget(targetCoords)
    local playerPed = PlayerPedId()
    
    TaskGoToCoordAnyMeans(playerPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
    
    local startTime = GetGameTimer()
    local timeout = 15000
    local lastCheck = 0
    
    while true do
        local currentTime = GetGameTimer()
        
        if currentTime - lastCheck >= 500 then
            lastCheck = currentTime
            
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance < 3.0 then
                ClearPedTasks(playerPed)
                return true
            end
            
            if currentTime - startTime > timeout then
                ClearPedTasks(playerPed)
                return false
            end
            
            if not autoMining.active then
                ClearPedTasks(playerPed)
                return false
            end
        end
        
        Wait(100)
    end
end

local function formatTime(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

local function stopAutoMining()
    if autoMining.active then
        autoMining.active = false
        autoMining.lastUsed = GetGameTimer()
        
        if autoMining.thread then
            autoMining.thread = nil
        end
        
        if autoMining.timerThread then
            autoMining.timerThread = nil
        end
        
        lib.hideTextUI()
        
        ClearPedTasks(PlayerPedId())
        lib.notify({ 
            title = 'DISNAKER', 
            description = 'Auto mining dihentikan!', 
            type = 'inform', 
            duration = 3500
        })
    end
end

local spawnSingleRock
local function tambangBatu(rockData, rockId)
    if not DoesEntityExist(rockData.entity) then
        return
    end
    
    if not rocksSpawned[rockId] then
        return
    end
    
    local playerPed = PlayerPedId()
    
    local progressConfig = {
        duration = 3000,
        label = "Menambang batu...",
        useWhileDead = false,
        canCancel = not autoMining.active,
        disable = {
            car = true,
            move = true,
        },
        anim = { dict = 'melee@hatchet@streamed_core', clip = 'plyr_rear_takedown_b', flag = 1 },
        prop = { bone = 28422, model = 'prop_tool_pickaxe', pos = vec3(0.09, -0.05, -0.02), rot = vec3(-78.0, 13.0, 28.0) }
    }
    
    if lib.progressBar(progressConfig) then
        if DoesEntityExist(rockData.entity) and rocksSpawned[rockId] then
            disnaker('dapat', 'tambang', nil, Lokasi.Miner.dapatBatu)
            exports.ox_target:removeLocalEntity(rockData.entity, {'tambangBatu_' .. rockId, 'autoTambangBatu_' .. rockId})
            rocksSpawned[rockId] = nil
            DeleteEntity(rockData.entity)
            
            CreateThread(function()
                Wait(500)
                local newRockPos = getRandomPositionInZone(miningZone.coords, miningZone.distance * 0.8)
                spawnSingleRock(newRockPos)
            end)
        else
            lib.notify({ title = 'DISNAKER', description = 'Batu sudah tidak ada!', type = 'error', duration = 3500})
        end
    else
        ClearPedTasks(playerPed)
        if autoMining.active then
            stopAutoMining()
        end
    end
    
    RemoveAnimDict(dict)
end

local function startAutoMining()
    local currentTime = GetGameTimer()
    
    if autoMining.lastUsed > 0 and (currentTime - autoMining.lastUsed) < autoMining.cooldown then
        local remainingCooldown = math.ceil((autoMining.cooldown - (currentTime - autoMining.lastUsed)) / 1000)
        lib.notify({ 
            title = 'DISNAKER', 
            description = 'Auto mining masih cooldown! Sisa: ' .. remainingCooldown .. ' detik', 
            type = 'error', 
            duration = 3500
        })
        return
    end
    
    autoMining.active = true
    autoMining.startTime = currentTime
    
    lib.notify({ 
        title = 'DISNAKER', 
        description = 'Auto mining dimulai! Durasi: 10 menit', 
        type = 'success', 
        duration = 3500
    })
    
    autoMining.timerThread = CreateThread(function()
        while autoMining.active do
            local currentTime = GetGameTimer()
            local elapsedTime = currentTime - autoMining.startTime
            local remainingTime = autoMining.maxDuration - elapsedTime
            
            if remainingTime > 0 then
                local timeString = formatTime(remainingTime)
                lib.showTextUI('[E] Stop Mining | Sisa Waktu: ' .. timeString, {
                    position = "left-center",
                    icon = 'fa-solid fa-pickaxe',
                })
            else
                break
            end
            
            Wait(1000)
        end
        
        lib.hideTextUI()
        autoMining.timerThread = nil
    end)
    
    autoMining.thread = CreateThread(function()
        local lastRockCheck = 0
        
        while autoMining.active do
            local currentTime = GetGameTimer()
            
            if currentTime - autoMining.startTime >= autoMining.maxDuration then
                lib.notify({ 
                    title = 'DISNAKER', 
                    description = 'Auto mining selesai! Durasi maksimal tercapai', 
                    type = 'inform', 
                    duration = 3500
                })
                stopAutoMining()
                break
            end
            
            if currentTime - lastRockCheck >= 2000 then
                lastRockCheck = currentTime
                
                local playerCoords = GetEntityCoords(PlayerPedId())
                local nearestRock = findNearestRock(playerCoords)
                
                if nearestRock then
                    local walkSuccess = walkToTarget(nearestRock.data.coords)
                    
                    if walkSuccess and autoMining.active then
                        Wait(500)
                        if DoesEntityExist(nearestRock.data.entity) and rocksSpawned[nearestRock.id] then
                            tambangBatu(nearestRock.data, nearestRock.id)
                        end
                    end
                    
                    Wait(1000)
                else
                    Wait(3000)
                end
            else
                Wait(500)
            end
        end
        
        autoMining.thread = nil
    end)
end

spawnSingleRock = function(rockPos)
    local rockModel = rockModels[math.random(1, #rockModels)]
    local rockHash = GetHashKey(rockModel)
    
    RequestModel(rockHash)
    local timeout = 0
    while not HasModelLoaded(rockHash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(rockHash) then
        return nil
    end
    
    local rock = CreateObject(rockHash, rockPos.x, rockPos.y, rockPos.z, false, false, false)
    
    if not DoesEntityExist(rock) then
        SetModelAsNoLongerNeeded(rockHash)
        return nil
    end
    
    PlaceObjectOnGroundProperly(rock)
    FreezeEntityPosition(rock, true)
    SetEntityAsMissionEntity(rock, true, true)

    local rockId = "rock_" .. GetGameTimer() .. "_" .. math.random(1000, 9999)
    
    local rockData = {
        entity = rock,
        coords = rockPos,
        model = rockModel,
        id = rockId
    }
    
    rocksSpawned[rockId] = rockData
    
    exports.ox_target:addLocalEntity(rock, {
        {
            name = 'tambangBatu_' .. rockId,
            icon = 'fas fa-hammer',
            label = 'Tambang Batu',
            groups = 'miner',
            distance = 3.0,
            onSelect = function()
                local success = lib.skillCheck({'easy'}, {'w', 'a', 's', 'd'})
                if success then
                    tambangBatu(rockData, rockId)
                end
            end,
        },
        {
            name = 'autoTambangBatu_' .. rockId,
            icon = 'fas fa-cog',
            label = 'Tambang Batu Otomatis',
            groups = 'miner',
            distance = 3.0,
            onSelect = function()
                if autoMining.active then
                    lib.notify({ 
                        title = 'DISNAKER', 
                        description = 'Auto mining sedang aktif!', 
                        type = 'error', 
                        duration = 3500
                    })
                    return
                end
                startAutoMining()
            end,
        }
    })
    
    SetModelAsNoLongerNeeded(rockHash)
    return rock
end

local function createRock()
    local rockCount = math.random(8, 15)
    
    for i = 1, rockCount do
        Citizen.CreateThread(function()
            Wait(i * 200)
            local rockPos = getRandomPositionInZone(miningZone.coords, miningZone.distance * 0.8)
            spawnSingleRock(rockPos)
        end)
    end
end

local function deleteAllRocks()
    local rocksToDelete = {}
    
    for rockId, rockData in pairs(rocksSpawned) do
        if DoesEntityExist(rockData.entity) then
            table.insert(rocksToDelete, {id = rockId, data = rockData})
        end
    end
    
    CreateThread(function()
        for i, rock in ipairs(rocksToDelete) do
            exports.ox_target:removeLocalEntity(rock.data.entity, {'tambangBatu_' .. rock.id, 'autoTambangBatu_' .. rock.id})
            DeleteEntity(rock.data.entity)
            rocksSpawned[rock.id] = nil
            
            if i % 3 == 0 then
                Wait(50)
            end
        end
    end)
end

function miningZone:onEnter()
    if QBCore.Functions.GetPlayerData().job.name == 'miner' and QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
        createRock()
    end
end

function miningZone:onExit()
    if QBCore.Functions.GetPlayerData().job.name == 'miner' and QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
        deleteAllRocks()
        if autoMining.active then
            stopAutoMining()
        end
    end
end

RegisterCommand('stopmining', function()
    if autoMining.active then
        stopAutoMining()
    else
        lib.notify({ 
            title = 'DISNAKER', 
            description = 'Auto mining tidak sedang aktif!', 
            type = 'error', 
            duration = 3500
        })
    end
end, false)

CreateThread(function()
    while true do
        Wait(300000)
        
        local cacheSize = 0
        for _ in pairs(cachedGroundZ) do
            cacheSize = cacheSize + 1
        end
        
        if cacheSize > 100 then
            cachedGroundZ = {}
        end
    end
end)

--Lebur dan Cuci
CreateThread(function()
    for k,v in pairs(cucibatu) do
        lib.points.new({
            coords = Lokasi.Miner.cuciBatu,
            distance = 2,
            onEnter = function()
                if not sibukMining and QBCore.Functions.GetPlayerData().job.name == 'miner' and QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
                lib.showTextUI('[E] - Cuci Batu', {
                    position = "left-center",
                    icon = 'hands'
                })
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            nearby = function()
                if IsControlJustReleased(0, 38) then
                    if not sibukMining and QBCore.Functions.GetPlayerData().job.name == 'miner' and QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
                        local ox_inventory = exports.ox_inventory
                        local batu = ox_inventory:Search(2, 'stone')

                        if not QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then return lib.notify({ title = 'DISNAKER', description = 'Ganti Baju Terlebih dahulu!', type = 'error', duration = 3500}) end

                        if not sibukMining then
                            if batu >= 3 then
                                local success = lib.skillCheck({'easy'}, {'w', 'a', 's', 'd'})
                                if success then
                                    sibukMining = true
                                    FreezeEntityPosition(cache.ped, 1)
                                    if lib.progressBar({
                                        duration = 6000,
                                        label = 'Mencuci Batu',
                                        useWhileDead = false,
                                        canCancel = false,
                                        disable = { move = true, car = true, combat = true },
                                        anim = { scenario = "PROP_HUMAN_BUM_BIN"},
                                        prop = { bone = 60309, model = 'prop_rock_5_smash1', pos = vec3(0.09, -0.05, -0.02), rot = vec3(-78.0, 13.0, 28.0) }
                                    }) then 
                                        FreezeEntityPosition(cache.ped, 0)
                                        disnaker('cuci', 'tambang', Lokasi.Miner.cuciKurang, Lokasi.Miner.cuciDapat)
                                        sibukMining = false
                                        ClearPedTasks(cache.ped)
                                    else 
                                        ClearPedTasks(cache.ped)
                                        FreezeEntityPosition(cache.ped, 0)
                                        sibukMining = false
                                    end
                                else
                                    lib.notify({ title = 'DISNAKER', description = 'Kamu gagal!', type = 'error', duration = 3500})
                                end	
                            else
                                lib.notify({ title = 'DISNAKER', description = 'Tidak memiliki batu!', type = 'error', duration = 3500})
                            end
                        end
                    end
                end
            end
        })
    end
end)

local function leburBatu()
    if not QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
        lib.notify({ title = 'DISNAKER', description = 'Ganti Baju Terlebih Dahulu!', type = 'error', duration = 3500})
        return
    end

    if sibukMining then return end
    sibukMining = true

    local success = lib.skillCheck({'easy'}, {'w', 'a', 's', 'd'})
    if success then
        exports.ox_inventory:Progress({
            duration = 15000,
            label = 'Melebur Batu...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false
            },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        }, function(cancel)
            if not cancel then
                tb.ss("tk-disnaker:mining:lebur")
                sibukMining = false
            else
                sibukMining = false
                lib.notify({ title = 'DISNAKER', description = 'Proses Dibatalkan!', type = 'error', duration = 3500})
            end
        end)
    else
        sibukMining = false
        lib.notify({ title = 'DISNAKER', description = 'Gagal!', type = 'error', duration = 3500})
    end
end

exports.ox_target:addBoxZone({
    coords = Lokasi.Miner.leburBatu,
    size = vec3(2, 2, 2),
    rotation = 45,
    debug = drawZones,
    options = {
        {
            icon = 'fas fa-hammer',
            label = 'Lebur Batu',
            groups = 'miner',
            onSelect = function()
                leburBatu()
            end,
            canInteract = function(entity) return QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] end
        }
    }
})

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    deleteAllRocks()
    if autoMining.active then
        lib.hideTextUI()
        stopAutoMining()
    end

    cachedGroundZ = {}
end)