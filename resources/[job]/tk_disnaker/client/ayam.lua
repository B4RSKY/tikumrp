local QBCore = exports['qb-core']:GetCoreObject()

local Config = {
    ChickenZone = {
        coords = vector3(2378.22, 5053.38, 46.44),
        radius = 10.0,
        debug = false
    },
    MaxChickens = 10,
    ChickenModel = `a_c_hen`,
    ChickenHealth = 100,
    RespawnDelay = 2000,
}

local chickens = {}
local isInZone = false
local chickenZone = nil

local function SpawnChicken()
    if #chickens >= Config.MaxChickens then return end
    
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * Config.ChickenZone.radius
    local x = Config.ChickenZone.coords.x + (math.cos(angle) * distance)
    local y = Config.ChickenZone.coords.y + (math.sin(angle) * distance)
    local z = Config.ChickenZone.coords.z
    
    local raycast = StartShapeTestRay(x, y, z + 10, x, y, z - 10, 1, 0, 0)
    local _, hit, endCoords = GetShapeTestResult(raycast)
    
    if hit then
        z = endCoords.z
    end
    
    RequestModel(Config.ChickenModel)
    while not HasModelLoaded(Config.ChickenModel) do
        Wait(1)
    end
    
    local chicken = CreatePed(28, Config.ChickenModel, x, y, z, math.random(0, 360), false, true)
    
    if DoesEntityExist(chicken) then
        SetEntityHealth(chicken, Config.ChickenHealth)
        TaskWanderStandard(chicken, 0, 0)
        SetPedCombatAttributes(chicken, 17, true)
        SetBlockingOfNonTemporaryEvents(chicken, true)
        SetEntityCanBeDamaged(chicken, true)
        
        table.insert(chickens, chicken)
        
        if Config.ChickenZone.debug then
            print(("Spawned chicken %s at %.2f, %.2f, %.2f"):format(chicken, x, y, z))
        end
    end
    
    SetModelAsNoLongerNeeded(Config.ChickenModel)
end

local function RemoveChicken(chicken)
    for i, v in pairs(chickens) do
        if v == chicken then
            table.remove(chickens, i)
            break
        end
    end
    
    if DoesEntityExist(chicken) then
        DeleteEntity(chicken)
    end
end

local function InitialSpawn()
    for i = 1, Config.MaxChickens do
        SpawnChicken()
        Wait(100)
    end
end

local function CleanupChickens()
    for _, chicken in pairs(chickens) do
        if DoesEntityExist(chicken) then
            DeleteEntity(chicken)
        end
    end
    chickens = {}
end

local function OnChickenDeath(chicken)    
    exports.ox_target:addLocalEntity(chicken, {
        {
            name = 'collect_chicken',
            icon = 'fas fa-hand-paper',
            label = 'Ambil Ayam',
            groups = 'slaughterer',
            onSelect = function()
                if GetSelectedPedWeapon(PlayerPedId()) == GetHashKey('WEAPON_MACHETE')  then
                    if lib.progressBar({
                        duration = 3000,
                        label = 'Mengambil ayam...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            car = true,
                            move = true,
                            combat = true
                        },
                        anim = {dict = 'amb@medic@standing@kneel@base', clip = 'base'}
                    }) then
                        disnaker('dapat', 'tayam', nil, Lokasi.Ayam.dapatAyam)
                        RemoveChicken(chicken)
                        SetTimeout(Config.RespawnDelay, function()
                            if isInZone then
                                SpawnChicken()
                            end
                        end)
                        
                        lib.notify({
                            title = 'DISNAKER',
                            description = 'Berhasil mengambil ayam!',
                            type = 'success'
                        })
                    else
                        ClearPedTasks(PlayerPedId())
                    end
                else
                    lib.notify({
                        title = 'DISNAKER',
                        description = 'Anda membutuhkan parang untuk mengambil ayam!',
                        type = 'success'
                    })
                end
            end
        }
    })
end

local function SetupZone()
    chickenZone = lib.zones.sphere({
        coords = Config.ChickenZone.coords,
        radius = Config.ChickenZone.radius,
        debug = Config.ChickenZone.debug,
        onEnter = function()
            if QBCore.Functions.GetPlayerData().job.name == 'slaughterer' and QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
                isInZone = true
                lib.notify({
                    title = 'DISNAKER',
                    description = 'Masuk ke area ayam. Bunuh ayam untuk mengambilnya!',
                    type = 'inform'
                })
                InitialSpawn()
            else
                lib.notify({
                    title = 'DISNAKER',
                    description = 'Anda Bukan Pekerja Ayam/Belum Ganti Baju!',
                    type = 'success'
                })
            end
        end,
        onExit = function()
            if QBCore.Functions.GetPlayerData().job.name == 'slaughterer' and QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
                isInZone = false
                lib.notify({
                    title = 'DISNAKER',
                    description = 'Keluar dari area ayam',
                    type = 'inform'
                })
                CleanupChickens()
            else
                lib.notify({
                    title = 'DISNAKER',
                    description = 'Anda Bukan Pekerja Ayam/Belum Ganti Baju!',
                    type = 'success'
                })
            end
        end
    })
end

local function MainLoop()
    CreateThread(function()
        while true do
            local sleep = 1000
            
            if isInZone then
                sleep = 500
                for i = #chickens, 1, -1 do
                    local chicken = chickens[i]
                    if DoesEntityExist(chicken) then
                        if IsEntityDead(chicken) then
                            OnChickenDeath(chicken)
                            table.remove(chickens, i)
                        end
                    else
                        table.remove(chickens, i)
                    end
                end
            end
            
            Wait(sleep)
        end
    end)
end

--Proses
local function BunuhAyam()
    SendNUIMessage({
        type = "killChicken"
    })
    SetNuiFocus(true, true)
    SetMouseCursorVisibleInMenus(false)
end

local function PotongAyam()
    SendNUIMessage({
        type = "chickenCut"
    })
    SetNuiFocus( true, true)
    SetMouseCursorVisibleInMenus(false)
end

local function KemasAYam()
    SendNUIMessage({
        type = "chickenPackage"
    })
    SetNuiFocus(true, true)
    SetMouseCursorVisibleInMenus(false)
end

RegisterNUICallback('cutHead', function(data)
    SetNuiFocus(false, false)
    SetMouseCursorVisibleInMenus(true)
    disnaker('bunuh', 'tayam', Lokasi.Ayam.bunuhKurang, Lokasi.Ayam.bunuhDapat)
end)

RegisterNUICallback('lineDone', function(data)
    SetNuiFocus(false, false)
    SetMouseCursorVisibleInMenus(true)
    ClearPedTasksImmediately(PlayerPedId())
    disnaker('potong', 'tayam', Lokasi.Ayam.PotongKurang, Lokasi.Ayam.PotongDapat)
end)

RegisterNUICallback('packageDone', function(data)
    SetNuiFocus(false, false)
    SetMouseCursorVisibleInMenus(true)
    disnaker('kemas', 'tayam', Lokasi.Ayam.kemasAyamDapat, Lokasi.Ayam.kemasAyamKurang)
end)

exports.ox_target:addBoxZone({
    coords = Lokasi.Ayam.potongAyam,
    size = vec3(2, 2, 2),
    rotation = 45,
    debug = drawZones,
    options = {
        {
            icon = 'fas fa-drumstick-bite',
            label = 'Potong Ayam',
            groups = 'slaughterer',
            onSelect = function()
                PotongAyam()
            end
        }
    }
})

exports.ox_target:addBoxZone({
    coords = Lokasi.Ayam.bunuhAyam,
    size = vec3(2, 2, 2),
    rotation = 45,
    debug = drawZones,
    options = {
        {
            icon = 'fas fa-drumstick-bite',
            label = 'Bunuh Ayam',
            groups = 'slaughterer',
            onSelect = function()
                BunuhAyam()
            end
        }
    }
})

exports.ox_target:addBoxZone({
    coords = Lokasi.Ayam.kemasAyam,
    size = vec3(2, 2, 2),
    rotation = 45,
    debug = drawZones,
    options = {
        {
            icon = 'fas fa-drumstick-bite',
            label = 'Kemas Ayam',
            groups = 'slaughterer',
            onSelect = function()
                KemasAYam()
            end
        }
    }
})

--Main EVent
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetupZone()
    MainLoop()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if chickenZone then
        chickenZone:remove()
    end
    CleanupChickens()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        while not QBCore do
            Wait(100)
        end
        SetupZone()
        MainLoop()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if chickenZone then
            chickenZone:remove()
        end
        CleanupChickens()
    end
end)