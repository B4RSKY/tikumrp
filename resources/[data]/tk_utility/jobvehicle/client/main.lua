local Config = require 'jobvehicle.shared.config'
local QBCore = exports['qb-core']:GetCoreObject()

local ped = {}
local vehPreview = nil

local function getRankVehicles(vehicle)
    local myRank = QBCore.Functions.GetPlayerData().job.grade.level
    local list = vehicle

    local index = 1
    local results = {}
    for model, data in pairs(list) do
        if data.forRank[myRank] and IsModelValid(model) then
            results[index] = {model = model, label = data.label, price = data.price, prefixPlate = data.prefixPlate}
            index += 1
        end
    end

    return results
end

local function createTargetPed(model, coords, options)
    local newoptions = {}
    
    lib.requestModel(model, 50000)
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1, coords.w, false, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    if type(options) == "table" and #options > 0 then
        for i=1, #options do
            local data = options[i]
            local opt = {
                name = data.name,
                label = data.label,
                icon = data.icon,
            }
            opt.groups = data.groups
            opt.distance = data.distance
            opt.onSelect = data.action
            newoptions[#newoptions+1] = opt
        end
    end

    if #newoptions > 0 then
        exports.ox_target:addLocalEntity(ped, newoptions)
    end

    return ped
end

local function destroyPreviewCam(vehicle, enterVehicle)
    if not DoesEntityExist(vehicle) then return end
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local vehpos = GetEntityCoords(vehicle)
    local pos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 5.0, 1.0)
    SetCamCoord(cam, pos.x, pos.y, pos.z + 0.4)
    PointCamAtCoord(cam, vehpos.x,vehpos.y,vehpos.z + 0.2)
    
    if enterVehicle then
        DoScreenFadeOut(500)
        Wait(1000)
        DoScreenFadeIn(500)
        RenderScriptCams(false, true, 1500,  false,  false)
    else
        RenderScriptCams(false, true, 1500,  false,  false)
    end
end

local function createPreviewCam(vehicle)
    if not DoesEntityExist(vehicle) then return end
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    RenderScriptCams(true, true, 1500,  true,  true)
    local vehpos = GetEntityCoords(vehicle)
    local pos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 15.0, 1.0)
    local camF = GetGameplayCamFov()
    SetCamCoord(cam, pos.x, pos.y, pos.z + 4.2)
    PointCamAtCoord(cam, vehpos.x,vehpos.y,vehpos.z + 0.2)
    SetCamFov(cam, camF - 20)
end

local function destroyPreviewVehicle()
    if DoesEntityExist(vehPreview) then
        destroyPreviewCam(vehPreview)
        SetEntityAsMissionEntity(vehPreview, true, true)
        DeleteEntity(vehPreview)
    end
end

local function srtingTrim(s)
    if not s or type(s) ~= 'string' then return end
    local trimmed = s:gsub('^%s*(.-)%s*$', '%1')
    return trimmed
end

local function getPlate ( vehicle )
    if not DoesEntityExist(vehicle) then return end
    local vehPlate = GetVehicleNumberPlateText(vehicle)
    return srtingTrim(vehPlate)
end

local function createPlyVeh ( model, coords, cb, network )
    network = network == nil and true or network
    lib.requestModel(model, 1500)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, network, false)
    if network then
        local id = NetworkGetNetworkIdFromEntity(veh)
        SetNetworkIdCanMigrate(id, true)
        SetEntityAsMissionEntity(veh, true, true)
    end
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetModelAsNoLongerNeeded(model)
    if cb then cb(veh) else return veh end
end

local function previwVehicle(veh, coords, label)
    local model = veh.model
    local price = veh.price
    local vehLabel = veh.label
    local prefixPlate = veh.prefixPlate
    
    lib.requestModel(model, 1500)
    vehPreview = createPlyVeh(model, coords, nil, false)
    createPreviewCam(vehPreview)

    lib.registerContext({
        id = 'tk_job:jobvehshopAction',
        title = label,
        onBack = destroyPreviewVehicle,
        onExit = destroyPreviewVehicle,
        menu = 'tk_job:jobvehshopMenu',
        options = {
            {
                title = vehLabel,
                description = 'Beli Kendaraan?',
                onSelect = function(args)
                   local playerData = QBCore.Functions.GetPlayerData()
                    if playerData.money.cash < price then
                        lib.notify({
                            title = 'DEALER',
                            description = 'Uang tunai Anda tidak cukup.',
                            type = 'error'
                        })
                        return destroyPreviewVehicle()
                    end

                    destroyPreviewVehicle()
                    Wait(100)
                    local newVeh = createPlyVeh(model, coords)
                    TaskWarpPedIntoVehicle(cache.ped, newVeh, -1)
                    SetVehicleFixed(newVeh)
                    local plate = exports["vehicleshop"]:GeneratePlate()
                    SetVehicleNumberPlateText(newVeh, plate)
                    exports["cdn-fuel"]:SetFuel(newVeh, 100)

                    local jobName = playerData.job.name
                    local vehicleModel = model
                    local getplate = getPlate(newVeh)

                    TriggerServerEvent('tk_job:veh', jobName, vehicleModel, getplate)
                end,
                metadata = {
                    Price = 'TK$' .. lib.math.groupdigits(price, '.')
                }
            },
        },
    })
    lib.showContext('tk_job:jobvehshopAction')
end

local function showMenu(data)
    local filteredVehicles = getRankVehicles(data.vehicle)
    if not filteredVehicles[1] then return
        lib.notify({
            title = 'DEALER',
            description = 'Tidak ada kendaraan untuk pangkat anda',
            type = 'error'
        })
    end

    local context = {
        id = 'tk_job:jobvehshopMenu',
        title = data.label,
        options = {}
    }

    for i=1, #filteredVehicles do
        local veh = filteredVehicles[i]
        local class = GetVehicleClassFromName(veh.model)
        context.options[#context.options+1] = {
            title = veh.label,
            icon = 'car',
            description = 'Lihat Kendaraan',
            onSelect = function ()
                return previwVehicle(veh, data.spawn, data.label)
            end
        }
    end

    lib.registerContext(context)
    lib.showContext('tk_job:jobvehshopMenu')
end

CreateThread(function ()
    local vehShopConfig = Config.JobVehicleShop
    for i=1, #vehShopConfig do
        local data = vehShopConfig[i]
        local pedModel = joaat(data.ped.model)
        local pedCoords = data.ped.coords
        local groups = data.job

        ped[i] = createTargetPed(pedModel, pedCoords, {
            {
                label = "Open Shops",
                icon = "fas fa-warehouse",
                action = function ()
                    showMenu(data)
                end,
                groups = groups,
                distance = 1.5
            }
        })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if DoesEntityExist(vehPreview) then
            DeleteEntity(vehPreview)
        end
    end
end)