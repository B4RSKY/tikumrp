local client = require 'modules.framework.client'
local target = require 'modules.target.client'
local utils = require 'modules.utils.client'

--- Events

RegisterNetEvent('bankrobbery:client:UseGreenLaptop', function(data)
    if not currentBank or currentBank ~= data.bank then return end

    local hasItem = client.hasItems('laptop_green')
    if not hasItem then
        utils.notify(Locales['missing_items'], 'error', 2500)
        return
    end

    if Config.Banks[data.bank].hacked then
        utils.notify(Locales['laptop_hit'], 'success', 3000)
        return
    end

    local canAttempt = lib.callback.await('bankrobbery:server:CanAttemptBankRobbery', 200, data.bank)
    if not canAttempt then return end

    local ped = cache.ped
    TaskTurnPedToFaceEntity(ped, data.entity, 1.0)

    if lib.progressBar({
        duration = math.random(5000, 10000),
        label = Locales['progressbar_laptop'],
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true, mouse = false },
        anim = { dict = 'anim@gangops@facility@servers@', clip = 'hotwire', flag = 16 }
    }) then 
        TriggerServerEvent('bankrobbery:server:LaptopDamage', 'laptop_green')
        utils.alertPolice(Config.Banks[data.bank].type)
        LaptopAnimation(data.bank)
    else
        utils.notify(Locales['canceled'], 'error', 3000)
    end
end)

--- Threads

if Config.FleecaBanks == 'K4MB1' or Config.FleecaBanks == 'default' then 
    target.AddBoxZone('bankrobbery_panel_pinkcage', vec3(311.6, -284.60, 54.02), 0.2, 0.46, {
        name = 'bankrobbery_panel_pinkcage',
        heading = 249,
        debugPoly = Config.Debug,
        minZ = 54.02,
        maxZ = 54.76
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['PinkCage'].hacked
                end,
                bank = 'PinkCage'
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['PinkCage'].hacked
                end,
                bank = 'PinkCage',
                job = 'police'
            }
        },
        distance = 1.5,
    })

    target.AddBoxZone('bankrobbery_panel_legion', vec3(147.19, -1046.2, 29.26), 0.3, 0.44, {
        name = 'bankrobbery_panel_legion',
        heading = 249,
        debugPoly = Config.Debug,
        minZ = 29.26,
        maxZ = 29.96
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['Legion'].hacked
                end,
                bank = 'Legion'
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['Legion'].hacked
                end,
                bank = 'Legion',
                job = 'police'
            }
        },
        distance = 1.5,
    })

    target.AddBoxZone('bankrobbery_panel_hawick', vec3(-353.47, -55.48, 48.92), 0.2, 0.46, {
        name = 'bankrobbery_panel_hawick',
        heading = 249,
        debugPoly = Config.Debug,
        minZ = 48.92,
        maxZ = 49.56
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['Hawick'].hacked
                end,
                bank = 'Hawick',
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['Hawick'].hacked
                end,
                bank = 'Hawick',
                job = 'police'
            }
        },
        distance = 1.5,
    })

    target.AddBoxZone('bankrobbery_panel_delperro', vec3(-1210.38, -336.40, 37.68), 0.24, 0.46, {
        name = 'bankrobbery_panel_delperro',
        heading = 297,
        debugPoly = Config.Debug,
        minZ = 37.67,
        maxZ = 38.33
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['DelPerro'].hacked
                end,
                bank = 'DelPerro',
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['DelPerro'].hacked
                end,
                bank = 'DelPerro',
                job = 'police'
            }
        },
        distance = 1.5,
    })

    target.AddBoxZone('bankrobbery_panel_greatocean', vec3(-2956.48, 482.1, 15.50), 0.24, 0.46, {
        name = 'bankrobbery_panel_greatocean',
        heading = 358,
        debugPoly = Config.Debug,
        minZ = 15.50,
        maxZ = 16.20
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['GreatOcean'].hacked
                end,
                bank = 'GreatOcean',
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['GreatOcean'].hacked
                end,
                bank = 'GreatOcean',
                job = 'police'
            }
        },
        distance = 1.5,
    })

    target.AddBoxZone('bankrobbery_panel_sandy', vec3(1175.66, 2712.90, 38.0), 0.24, 0.46, {
        name = 'bankrobbery_panel_sandy',
        heading = 89,
        debugPoly = Config.Debug,
        minZ = 38.00,
        maxZ = 38.60
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['Sandy'].hacked
                end,
                bank = 'Sandy',
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['Sandy'].hacked
                end,
                bank = 'Sandy',
                job = 'police'
            }
        },
        distance = 1.5,
    })

elseif Config.FleecaBanks == 'gabz' then
    target.AddBoxZone('bankrobbery_panel_pinkcage', vec3(311.06, -284.67, 53.96), 0.4, 0.6, {
        name = 'bankrobbery_panel_pinkcage',
        heading = 340,
        debugPoly = Config.Debug,
        minZ = 53.96,
        maxZ = 54.76
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['PinkCage'].hacked
                end,
                bank = 'PinkCage'
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['PinkCage'].hacked
                end,
                bank = 'PinkCage',
                job = 'police'
            }
        },
        distance = 1.5,
    })

    target.AddBoxZone('bankrobbery_panel_legion', vec3(146.69, -1046.44, 29.27), 0.4, 0.6, {
        name = 'bankrobbery_panel_legion',
        heading = 340,
        debugPoly = Config.Debug,
        minZ = 29.27,
        maxZ = 29.97
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['Legion'].hacked
                end,
                bank = 'Legion'
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['Legion'].hacked
                end,
                bank = 'Legion',
                job = 'police'
            }
        },
        distance = 1.5,
    })

    target.AddBoxZone('bankrobbery_panel_hawick', vec3(-354.02, -55.61, 48.84), 0.4, 0.6, {
        name = 'bankrobbery_panel_hawick',
        heading = 338,
        debugPoly = Config.Debug,
        minZ = 48.84,
        maxZ = 49.64
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['Hawick'].hacked
                end,
                bank = 'Hawick',
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['Hawick'].hacked
                end,
                bank = 'Hawick',
                job = 'police'
            }
        },
        distance = 1.5,
    })

    target.AddBoxZone('bankrobbery_panel_delperro', vec3(-1210.75, -336.77, 37.58), 0.4, 0.6, {
        name = 'bankrobbery_panel_delperro',
        heading = 26,
        debugPoly = Config.Debug,
        minZ = 37.58,
        maxZ = 38.38
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['DelPerro'].hacked
                end,
                bank = 'DelPerro',
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['DelPerro'].hacked
                end,
                bank = 'DelPerro',
                job = 'police'
            }
        },
        distance = 1.5,
    })

    target.AddBoxZone('bankrobbery_panel_greatocean', vec3(-2956.33, 481.61, 15.50), 0.6, 0.4, {
        name = 'bankrobbery_panel_greatocean',
        heading = 358,
        debugPoly = Config.Debug,
        minZ = 15.50,
        maxZ = 16.30
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['GreatOcean'].hacked
                end,
                bank = 'GreatOcean',
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['GreatOcean'].hacked
                end,
                bank = 'GreatOcean',
                job = 'police'
            }
        },
        distance = 1.5,
    })

    target.AddBoxZone('bankrobbery_panel_sandy', vec3(1176.04, 2713.15, 37.89), 0.4, 0.6, {
        name = 'bankrobbery_panel_sandy',
        heading = 359,
        debugPoly = Config.Debug,
        minZ = 37.89,
        maxZ = 38.69
     }, {
        options = { 
            {
                type = 'client',
                event = 'bankrobbery:client:UseGreenLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Config.Banks['Sandy'].hacked
                end,
                bank = 'Sandy',
            },
            {
                type = 'server',
                event = 'bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Config.Banks['Sandy'].hacked
                end,
                bank = 'Sandy',
                job = 'police'
            }
        },
        distance = 1.5,
    })

end
