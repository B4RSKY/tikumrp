local client = require 'modules.framework.client'
local target = require 'modules.target.client'
local utils = require 'modules.utils.client'

RegisterNetEvent('bankrobbery:client:UseGoldCard', function()
    local hasItem = client.hasItems('security_card_02')
    if not hasItem then
        utils.notify(Locales['missing_items'], 'error', 2500)
        return
    end

    if Config.Banks['Pacific'].card then
        utils.notify(Locales['laptop_hit'], 'success', 3000)
        return
    end

    local canAttempt = lib.callback.await('bankrobbery:server:CanAttemptBankRobbery', 200, 'Pacific')
    if not canAttempt then return end

    local ped = cache.ped

    utils.alertPolice('pacific')

    SetEntityCoords(ped, 261.89, 223.5, 105.30, 1, 0, 0, 1)
    SetEntityHeading(ped, 255.92)

    lib.requestModel('p_ld_id_card_01')

    -- Remove Card
    TriggerServerEvent('bankrobbery:server:RemoveGoldCard')

    local pedco = GetEntityCoords(ped)
    local IdProp = CreateObject(`p_ld_id_card_01`, pedco, true, true, false)
    SetModelAsNoLongerNeeded(`p_ld_id_card_01`)

    local boneIndex = GetPedBoneIndex(ped, 28422)
    local panel = GetClosestObjectOfType(pedco, 4.0, `hei_prop_hei_securitypanel`, false, false, false)
    AttachEntityToEntity(IdProp, ped, boneIndex, 0.12, 0.028, 0.001, 10.0, 175.0, 0.0, true, true, false, true, 1, true)
    TaskStartScenarioInPlace(ped, 'PROP_HUMAN_ATM', 0, true)
    Wait(1500)

    AttachEntityToEntity(IdProp, panel, boneIndex, -0.09, -0.02, -0.08, 270.0, 0.0, 270.0, true, true, false, true, 1, true)
    FreezeEntityPosition(IdProp)
    Wait(500)

    ClearPedTasksImmediately(ped)
    PlaySoundFrontend(-1, 'ATM_WINDOW', 'HUD_FRONTEND_DEFAULT_SOUNDSET')

    SetEntityCoords(ped, vec3(261.83, 223.08, 105.28))
    SetEntityHeading(ped, 255.92)

    lib.playAnim(ped, 'mp_heists@keypad@', 'idle_a', 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(2500)

    lib.playAnim(ped, 'mp_heists@keypad@', 'exit', 2.0, 2.0, -1, 0, 0, false, false, false)
    Wait(1000)

    TriggerServerEvent('bankrobbery:server:SetGoldCard')
end)

RegisterNetEvent('bankrobbery:client:SetGoldCard', function()
    Config.Banks['Pacific'].card = true
end)

RegisterNetEvent('bankrobbery:client:UseRedLaptop', function(data)
    local hasItem = client.hasItems('laptop_red')
    if not hasItem then
        utils.notify(Locales['missing_items'], 'error', 2500)
        return
    end

    if Config.Banks['Pacific'].hacked then
        utils.notify(Locales['laptop_hit'], 'normal', 2500)
        return
    end

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
        TriggerServerEvent('bankrobbery:server:LaptopDamage', 'laptop_red')
        utils.alertPolice(Config.Banks[data.bank].type)
        LaptopAnimation(data.bank)
    else
        utils.notify(Locales['canceled'], 'error', 3000)
    end
end)

--- Threads

target.AddBoxZone('bankrobbery_panel_pacific', vec3(252.88, 228.55, 101.79), 0.3, 0.4, {
    name = 'bankrobbery_panel_pacific',
    heading = 68.00,
    debugPoly = Config.Debug,
    minZ = 101.79,
    maxZ = 102.39
 }, {
    options = { 
        {
            type = 'client',
            event = 'bankrobbery:client:UseRedLaptop',
            icon = 'fas fa-user-secret',
            label = Locales['panel_target_hack'],
            canInteract = function()
                return not (Config.Banks['Pacific'].hacked or Config.Banks['Vault'].goldhacked or not Config.Banks['Pacific'].card)
            end,
            bank = 'Pacific',
        },
        {
            type = 'server',
            event = 'bankrobbery:server:PDClose',
            icon = 'fas fa-door-closed',
            label = Locales['panel_target_pd'],
            canInteract = function()
                return Config.Banks['Pacific'].hacked
            end,
            bank = 'Pacific',
            job = 'police'
        }
    },
    distance = 1.5,
})

target.AddBoxZone('bankrobbery_pacific_card', vec3(262.31, 223.01, 106.29), 0.2, 0.5, {
    name = 'bankrobbery_pacific_card',
    heading = 250,
    debugPoly = Config.Debug,
    minZ = 106.29,
    maxZ = 106.99
 }, {
    options = { 
        {
            type = 'client',
            event = 'bankrobbery:client:UseGoldCard',
            icon = 'fas fa-user-secret',
            label = Locales['pacific_swipe_card'],
            canInteract = function()
                return not Config.Banks['Pacific'].card
            end,
        }
    },
    distance = 1.5,
})
