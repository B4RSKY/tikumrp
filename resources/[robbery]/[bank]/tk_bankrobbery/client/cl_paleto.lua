local client = require 'modules.framework.client'
local target = require 'modules.target.client'
local utils = require 'modules.utils.client'

RegisterNetEvent('bankrobbery:client:UseBlueLaptop', function(data)
    local hasItem = client.hasItems('laptop_blue')
    if not hasItem then
        utils.notify(Locales['missing_items'], 'error', 2500)
        return
    end

    if Config.Banks['Paleto'].outsideHack then
        utils.notify(Locales['laptop_hit'], 'success', 3000)
        return
    end

    local canAttempt = lib.callback.await('bankrobbery:server:CanAttemptBankRobbery', 200, 'Paleto')
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
        TriggerServerEvent('bankrobbery:server:LaptopDamage', 'laptop_blue')
        utils.alertPolice(Config.Banks[data.bank].type)
        LaptopAnimation(data.bank)
    else
        utils.notify(Locales['canceled'], 'error', 3000)
    end
end)

RegisterNetEvent('bankrobbery:client:SetOutsideHacked', function()
    Config.Banks['Paleto'].outsideHack = true
end)

RegisterNetEvent('bankrobbery:client:UseGreenCard', function()
    local hasItem = client.hasItems('security_card_01')
    if not hasItem then
        utils.notify(Locales['missing_items'], 'error', 2500)
        return
    end

    if not Config.Banks['Paleto'].outsideHack then
        utils.notify(Locales['paleto_lockdown'], 'error', 4500)
        Wait(5000)
        utils.notify(Locales['paleto_lockdown2'], 'error', 4500)
        return
    end

    if lib.progressBar({
        duration = math.random(5000, 10000),
        label = Locales['progressbar_swipe_card'],
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true, mouse = false },
        anim = { dict = 'anim@gangops@facility@servers@', clip = 'hotwire', flag = 16 }
    }) then
        utils.alertPolice(Config.Banks['Paleto'].type)
        TriggerServerEvent('bankrobbery:server:SetBankHacked', 'Paleto')
        TriggerServerEvent('bankrobbery:server:RemoveGreenCard')
    else
        utils.notify(Locales['canceled'], 'error', 3000)
    end
end)

--- Targets

target.AddBoxZone('bankrobbery_panel_paleto', vec3(-109.39, 6483.2, 31.20), 0.3, 0.5, {
    name = 'bankrobbery_panel_paleto',
    heading = 226,
    debugPoly = Config.Debug,
    minZ = 31.20,
    maxZ = 32.20
}, {
    options = { 
        {
            type = 'client',
            event = 'bankrobbery:client:UseBlueLaptop',
            icon = 'fas fa-user-secret',
            label = Locales['panel_target_hack'],
            canInteract = function()
                return not Config.Banks['Paleto'].hacked
            end,
            bank = 'Paleto',
        }
    },
    distance = 1.5,
})

target.AddBoxZone('bankrobbery_card_paleto', vec3(-105.84, 6472.10, 31.79), 0.3, 0.4, {
    name = 'bankrobbery_card_paleto',
    heading = 73,
    debugPoly = Config.Debug,
    minZ = 31.79,
    maxZ = 32.19
}, {
    options = { 
        {
            type = 'client',
            event = 'bankrobbery:client:UseGreenCard',
            icon = 'fas fa-user-secret',
            label = Locales['pacific_swipe_card'],
            canInteract = function()
                return not Config.Banks['Paleto'].hacked
            end
        },
        {
            type = 'server',
            event = 'bankrobbery:server:PDClose',
            icon = 'fas fa-door-closed',
            label = Locales['panel_target_pd'],
            canInteract = function()
                return Config.Banks['Paleto'].hacked
            end,
            bank = 'Paleto',
            job = 'police'
        }
    },
    distance = 1.5,
})
