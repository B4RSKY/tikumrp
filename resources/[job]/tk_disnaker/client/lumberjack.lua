local QBCore = exports['qb-core']:GetCoreObject()
local ox_inventory = exports.ox_inventory
local isChopping = false
local spawnedTrees = {}
local currentZone = nil
local isAutoChopping = false
local autoChopEndTime = 0
local autoChopCooldownEnd = 0
local currentTarget = nil

local function FormatTime(ms)
    local totalSeconds = math.ceil(ms / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

local function isAutoTebangCooldown()
    return GetGameTimer() < autoChopCooldownEnd
end

local function getPohonTerdekat(excludeTree)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearestTree = nil
    local nearestDistance = math.huge
    
    for _, treeData in ipairs(spawnedTrees) do
        if DoesEntityExist(treeData.entity) and treeData.entity ~= excludeTree then
            local distance = #(playerCoords - treeData.coords)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestTree = treeData
            end
        end
    end
    
    return nearestTree
end

local function walkToPohon(treeCoords, callback)
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - treeCoords)
    
    if distance > 2.0 then
        TaskGoToCoordAnyMeans(ped, treeCoords.x, treeCoords.y, treeCoords.z, 1.5, 0, 0, 786603, 0xbf800000)

        local timeout = GetGameTimer() + 30000
        while GetGameTimer() < timeout and isAutoChopping do
            local currentCoords = GetEntityCoords(ped)
            local currentDistance = #(currentCoords - treeCoords)
            
            if currentDistance <= 2.5 then
                ClearPedTasks(ped)
                if callback then callback() end
                break
            end
            
            Wait(500)
        end
    else
        if callback then callback() end
    end
end

local function HasRequiredJob()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData.job then return false end
    return PlayerData.job.name == 'lumberjack'
end

local function tebangOtomatis()
    if isAutoChopping then return end
    if isAutoTebangCooldown() then
        local remaining = FormatTime(autoChopCooldownEnd - GetGameTimer())
        QBCore.Functions.Notify('Auto chop masih cooldown: ' .. remaining, 'error')
        return
    end
    
    isAutoChopping = true
    autoChopEndTime = GetGameTimer() + Lokasi.Lumberjack.autoTebangTime
    
    QBCore.Functions.Notify('Auto chopping dimulai untuk 10 menit!', 'success')
    
    CreateThread(function()
        while isAutoChopping and GetGameTimer() < autoChopEndTime do
            local remaining = FormatTime(autoChopEndTime - GetGameTimer())
            lib.showTextUI('[AUTO TEBANG] Waktu tersisa: ' .. remaining .. '\n\n[/stoptebang] untuk berhenti', {
                position = "left-center",
                icon = 'tree',
            })
            
            Wait(1000)
        end
        
        if isAutoChopping then
            stopTebangOtomatis()
        end
    end)
    prosesTebangOtomatis()
end

function stopTebangOtomatis()
    if not isAutoChopping then return end
    
    isAutoChopping = false
    autoChopCooldownEnd = GetGameTimer() + Lokasi.Lumberjack.autoTebangCD
    currentTarget = nil
    
    lib.hideTextUI()
    ClearPedTasks(PlayerPedId())
    QBCore.Functions.Notify('Auto chopping dihentikan. Cooldown 15 menit.', 'primary')
end

function prosesTebangOtomatis()
    CreateThread(function()
        while isAutoChopping and GetGameTimer() < autoChopEndTime do
            if not currentZone then
                stopTebangOtomatis()
                QBCore.Functions.Notify('Keluar dari zona, auto chop dihentikan', 'error')
                break
            end

            local nearestTree = getPohonTerdekat(currentTarget)
            if not nearestTree then
                Wait(5000)
                goto continue
            end
            
            currentTarget = nearestTree.entity
            
            walkToPohon(nearestTree.coords, function()
                if isAutoChopping and DoesEntityExist(nearestTree.entity) then
                    tebangPohon(nearestTree, true)
                end
            end)
            
            ::continue::
            Wait(1000)
        end
    end)
end

local function GetRandomTreePosition()
    local center = Lokasi.Lumberjack.ZonaTebang
    local radius = Lokasi.Lumberjack.ZoneRadius - 5.0
    
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius
    
    local x = center.x + math.cos(angle) * distance
    local y = center.y + math.sin(angle) * distance

    local found, z = GetGroundZFor_3dCoord(x, y, center.z + 20.0, false)
    local groundZ = found and z or center.z
    
    return vector3(x, y, groundZ)
end

local function SetEntityOutline(entity, enable)
    if enable then
        SetEntityDrawOutline(entity, true)
        SetEntityDrawOutlineColor(Lokasi.Lumberjack.OutlineColor.r, Lokasi.Lumberjack.OutlineColor.g, Lokasi.Lumberjack.OutlineColor.b, Lokasi.Lumberjack.OutlineColor.a)
        SetEntityDrawOutlineShader(1)
    else
        SetEntityDrawOutline(entity, false)
    end
end

local function SpawnWoodProp(treeCoords, isAutoMode)
    local model = GetHashKey('prop_log_02')
    RequestModel(model)
    
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    local offsetX = math.random(-2, 2) * 0.5
    local offsetY = math.random(-2, 2) * 0.5
    local woodCoords = vector3(treeCoords.x + offsetX, treeCoords.y + offsetY, treeCoords.z)
    
    local found, z = GetGroundZFor_3dCoord(woodCoords.x, woodCoords.y, woodCoords.z + 2.0, false)
    if found then
        woodCoords = vector3(woodCoords.x, woodCoords.y, z)
    end
    
    local prop = CreateObject(model, woodCoords.x, woodCoords.y, woodCoords.z, true, false, false)
    SetEntityAsMissionEntity(prop, true, true)
    FreezeEntityPosition(prop, false)

    if isAutoMode then
        SetTimeout(2000, function()
            if DoesEntityExist(prop) and isAutoChopping then
                DeleteObject(prop)
                local amount = math.random(Lokasi.Lumberjack.dapatWood.min, Lokasi.Lumberjack.dapatWood.max)
                disnaker('dapat', 'tkayu', nil, amount)
                QBCore.Functions.Notify('Auto pickup: ' .. amount .. ' kayu', 'success')
            end
        end)
        return
    end

    exports.ox_target:addLocalEntity(prop, {
        {
            name = 'pickup_wood_' .. prop,
            icon = 'fas fa-hand-paper',
            label = 'Ambil Kayu',
            onSelect = function()
                DeleteObject(prop)
                exports.ox_target:removeLocalEntity(prop, 'pickup_wood_' .. prop)
                
                local ped = PlayerPedId()
                lib.requestAnimDict('pickup_object')
                TaskPlayAnim(ped, 'pickup_object', 'pickup_low', 8.0, -8.0, 2000, 0, 0, false, false, false)
                
                Wait(2000)
                ClearPedTasks(ped)
                
                local amount = math.random(1, 4)
                disnaker('dapat', 'tkayu', nil, amount)
                QBCore.Functions.Notify('Kamu mendapat ' .. amount .. ' kayu', 'success')
            end
        }
    })
    
    SetTimeout(300000, function()
        if DoesEntityExist(prop) then
            exports.ox_target:removeLocalEntity(prop, 'pickup_wood_' .. prop)
            DeleteObject(prop)
        end
    end)
end

local function SpawnTree()
    if #spawnedTrees >= Lokasi.Lumberjack.MaxPohon then return end
    
    local coords = GetRandomTreePosition()
    local model = GetHashKey(Lokasi.Lumberjack.TreeModel)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    local tree = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAsMissionEntity(tree, true, true)
    FreezeEntityPosition(tree, true)
    SetEntityOutline(tree, true)
    
    local treeData = {
        entity = tree,
        coords = coords,
        targetId = 'tree_' .. tree
    }
    
    table.insert(spawnedTrees, treeData)
    
    exports.ox_target:addLocalEntity(tree, {
        {
            name = treeData.targetId,
            icon = 'fas fa-tree',
            label = 'Tebang Pohon',
            onSelect = function()
                tebangPohon(treeData, false)
            end
        },
        {
            name = treeData.targetId .. '_auto',
            icon = 'fas fa-cogs',
            label = 'Tebang Pohon Otomatis',
            onSelect = function()
                tebangOtomatis()
            end
        }
    })
end

function tebangPohon(treeData, isAutoMode)
    if isChopping then return end
    if not HasRequiredJob() then
        QBCore.Functions.Notify('Kamu tidak memiliki job tukang kayu!', 'error')
        return
    end
    
    isChopping = true
    local ped = PlayerPedId()
    local tree = treeData.entity
    
    local chopMsg = isAutoMode and 'Auto menebang pohon...' or 'Menebang pohon...'
    QBCore.Functions.Notify(chopMsg, 'primary')

    local success = lib.progressBar({
        duration = 8000,
        label = chopMsg,
        useWhileDead = false,
        canCancel = not isAutoMode, -- tidak bisa cancel jika auto mode
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'melee@large_wpn@streamed_core',
            clip = 'ground_attack_on_spot',
            flags = 1,
        },
        prop = { bone = 57005, model = 'prop_tool_fireaxe', pos = vec3(0.09, -0.05, -0.02), rot = vec3(-78.0, 13.0, 28.0) }
    })
    
    ClearPedTasks(ped)
    isChopping = false
    
    if success then
        SpawnWoodProp(treeData.coords, isAutoMode)
        exports.ox_target:removeLocalEntity(tree, treeData.targetId)
        exports.ox_target:removeLocalEntity(tree, treeData.targetId .. '_auto')
        DeleteObject(tree)

        for i, v in ipairs(spawnedTrees) do
            if v.entity == tree then
                table.remove(spawnedTrees, i)
                break
            end
        end
        
        local successMsg = isAutoMode and 'Auto chop berhasil!' or 'Berhasil menebang pohon!'
        QBCore.Functions.Notify(successMsg, 'success')
        
        SetTimeout(Lokasi.Lumberjack.respawnPohon, function()
            if currentZone then
                SpawnTree()
            end
        end)
    else
        local cancelMsg = isAutoMode and 'Auto chop dihentikan' or 'Penebangan dibatalkan'
        QBCore.Functions.Notify(cancelMsg, 'error')
        
        if isAutoMode then
            stopTebangOtomatis()
        end
    end
end

local function CleanupTrees()
    for _, treeData in ipairs(spawnedTrees) do
        if DoesEntityExist(treeData.entity) then
            exports.ox_target:removeLocalEntity(treeData.entity, treeData.targetId)
            exports.ox_target:removeLocalEntity(treeData.entity, treeData.targetId .. '_auto')
            DeleteObject(treeData.entity)
        end
    end
    spawnedTrees = {}
end

local function SpawnInitialTrees()
    for i = 1, Lokasi.Lumberjack.MaxPohon do
        SpawnTree()
        Wait(100)
    end
end

RegisterCommand('stoptebang', function()
    if isAutoChopping then
        stopTebangOtomatis()
    else
        lib.notify({ 
            title = 'DISNAKER', 
            description = 'Auto tebang tidak sedang aktif!', 
            type = 'error', 
            duration = 3500
        })
    end
end, false)

CreateThread(function()
    local zone = lib.zones.sphere({
        coords = Lokasi.Lumberjack.ZonaTebang,
        radius = Lokasi.Lumberjack.ZoneRadius,
        debug = false,
        onEnter = function()
            currentZone = true
            QBCore.Functions.Notify('Memasuki area penebangan kayu', 'primary')
            SpawnInitialTrees()
        end,
        onExit = function()
            currentZone = false
            if isAutoChopping then
                stopTebangOtomatis()
            end
            QBCore.Functions.Notify('Meninggalkan area penebangan kayu', 'primary')
            CleanupTrees()
        end
    })
end)

--Proses
local function potongKayu()
    if not HasRequiredJob() and QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
        lib.notify({ title = 'DISNAKER', description = 'Ganti baju terlebih dahulu', type = 'error', duration = 3500})
        return
    end

    if not exports['qb-core']:HasItem('wood', Lokasi.Lumberjack.ProsesKurang) then
        lib.notify({ title = 'DISNAKER', description = 'Tidak Memiliki Cukup Kayu', type = 'error', duration = 3500})
        return
    end

    local success = lib.skillCheck({'easy'}, {'w', 'a', 's', 'd'})
    if success then
        if lib.progressBar({
            duration = 5000,
            label = 'Memotong Kayu...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false
            },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        }) then 
            disnaker('proses', 'tkayu', Lokasi.Lumberjack.ProsesKurang, Lokasi.Lumberjack.ProsesDapat)
        else 
            lib.notify({ title = 'DISNAKER', description = 'Proses dibatalkan', type = 'error', duration = 3500})
        end
    end
end

exports.ox_target:addBoxZone({
    coords = Lokasi.Lumberjack.prosesKayu,
    size = vec3(2, 2, 2),
    rotation = 45,
    debug = drawZones,
    options = {
        {
            icon = 'fas fa-tree',
            label = 'Potong Kayu',
            groups = 'lumberjack',
            onSelect = function()
                potongKayu()
            end,
            canInteract = function(entity) return QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] end
        }
    }
})

local function kemasKayu()
    if not HasRequiredJob() and QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
        lib.notify({ title = 'DISNAKER', description = 'Ganti baju terlebih dahulu', type = 'error', duration = 3500})
        return
    end

    if not exports['qb-core']:HasItem('cutted_wood', Lokasi.Lumberjack.kemasKurang) then
        lib.notify({ title = 'DISNAKER', description = 'Tidak Memiliki Cukup Potongan Kayu', type = 'error', duration = 3500})
        return
    end

    local success = lib.skillCheck({'easy'}, {'w', 'a', 's', 'd'})
    if success then
        if lib.progressBar({
            duration = 5000,
            label = 'Mengemas Kayu...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false
            },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        }) then 
            disnaker('kemas', 'tkayu', Lokasi.Lumberjack.kemasKurang, Lokasi.Lumberjack.kemasDapat)
        else 
            lib.notify({ title = 'DISNAKER', description = 'Proses dibatalkan', type = 'error', duration = 3500})
        end
    end
end

exports.ox_target:addBoxZone({
    coords = Lokasi.Lumberjack.kemasKayu,
    size = vec3(2, 2, 2),
    rotation = 45,
    debug = drawZones,
    options = {
        {
            icon = 'fas fa-tree',
            label = 'Kemas Kayu',
            groups = 'lumberjack',
            onSelect = function()
                kemasKayu()
            end,
            canInteract = function(entity) return QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] end
        }
    }
})

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CleanupTrees()
    currentZone = false
    if isAutoChopping then
        stopTebangOtomatis()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isAutoChopping then
            lib.hideTextUI()
        end
        CleanupTrees()
    end
end)