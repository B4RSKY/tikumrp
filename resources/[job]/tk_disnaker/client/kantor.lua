local QBCore = exports['qb-core']:GetCoreObject()
local jobCenterPed = nil

local function jobCenter()
    RequestModel(Config.Disnaker.model)
    while not HasModelLoaded(Config.Disnaker.model) do
        Wait(100)
    end
    jobCenterPed = CreatePed(4, Config.Disnaker.model, Config.Disnaker.coords.x, Config.Disnaker.coords.y, Config.Disnaker.coords.z - 1.0, Config.Disnaker.coords.w, false, true)
    FreezeEntityPosition(jobCenterPed, true)
    SetEntityInvincible(jobCenterPed, true)
    SetBlockingOfNonTemporaryEvents(jobCenterPed, true)
    TaskStartScenarioInPlace(jobCenterPed, Config.Disnaker.scenario, 0, true)
    exports.ox_target:addLocalEntity(jobCenterPed, {
        {
            icon = 'fa-solid fa-briefcase',
            label = 'Pilih Pekerjaan',
            onSelect = function()
                local options = {}

                for jobName, jobData in pairs(Config.Jobs) do
                    table.insert(options, {
                        title = jobData.label,
                        description = jobData.description,
                        icon = jobData.icon,
                        onSelect = function()
                            TriggerServerEvent('tk-disnaker:dapatJob', jobName)
                        end
                    })
                end
                lib.registerContext({
                    id = 'job_center_menu',
                    title = 'Pusat Pekerjaan',
                    options = options
                })
                lib.showContext('job_center_menu')
            end
        },
        {
            icon = 'fa-solid fa-pencil',
            label = 'On Duty',
            onSelect = function()
                TriggerServerEvent('tk-jobs:duty', cache.serverId, true)
                lib.notify({ title = 'DISNAKER', description = 'ON DUTY! Selamat Bekerja', type = 'info', duration = 3500})
            end,
            canInteract = function(entity) return QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] == 'false' end
        },
        {
            icon = 'fa-solid fa-pencil',
            label = 'Off Duty',
            onSelect = function()
                TriggerServerEvent('tk-jobs:duty', cache.serverId, false)
                lib.notify({ title = 'DISNAKER', description = 'OFF DUTY! Selamat Beristirahat', type = 'info', duration = 3500})
            end,
            canInteract = function(entity) return QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] == 'true' end
        },
    })
end

CreateThread(function()
    jobCenter()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if jobCenterPed then
            exports.ox_target:removeLocalEntity(jobCenterPed)
            DeleteEntity(jobCenterPed)
        end
    end
end)