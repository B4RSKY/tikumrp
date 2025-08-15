local curWeapon = nil
local ox_inventory = exports.ox_inventory
local ped = cache.ped
local Weapons = {
    [`black_money`] = {object = `prop_money_bag_01`, item = 'black_money', rot = vector3(0,0,0)},
    [`weapon_pumpshotgun`] = {object = `w_sg_pumpshotgun`, item = 'WEAPON_PUMPSHOTGUN', rot = vector3(0,0,0)},
    [`weapon_assaultrifle`] = {object = `w_ar_assaultrifle`, item = 'WEAPON_ASSAULTRIFLE', rot = vector3(0,0,0)},
    [`WEAPON_BULLPUPRIFLE`] = {object = `w_ar_bullpuprifle`, item = 'WEAPON_BULLPUPRIFLE', rot = vector3(0,0,0)},
    [`WEAPON_SPECIALCARBINE`] = {object = `w_ar_specialcarbine`, item = 'WEAPON_SPECIALCARBINE', rot = vector3(0,0,0)},
    [`WEAPON_SNIPERRIFLE`] = {object = `w_sr_sniperrifle`, item = 'WEAPON_SNIPERRIFLE', rot = vector3(0,0,0)},
    [`WEAPON_SMG_MK2`] = {object = `w_sb_smgmk2`, item = 'WEAPON_SMG_MK2', rot = vector3(0,0,0)},
    [`WEAPON_SMG`] = {object = `w_sb_smg`, item = 'WEAPON_SMG', rot = vector3(0,0,0)},
    [`WEAPON_MUSKET`] = {object = `w_ar_musket`, item = 'WEAPON_MUSKET', rot = vector3(0,0,0)},
    [`WEAPON_MARKSMANRIFLE`] = {object = `w_sr_marksmanrifle`, item = 'WEAPON_MARKSMANRIFLE', rot = vector3(0,0,0)},
    [`WEAPON_HEAVYSNIPER`] = {object = `w_sr_heavysniper`, item = 'WEAPON_HEAVYSNIPER', rot = vector3(0,0,0)},
    [`WEAPON_FIREEXTINGUISHER`] = {object = `w_am_fire_exting`, item = 'WEAPON_FIREEXTINGUISHER', rot = vector3(0,92.5,0)}, 
    [`WEAPON_CARBINERIFLE`] = {object = `w_ar_carbinerifle`, item = 'WEAPON_CARBINERIFLE', rot = vector3(0,0,0)},
    [`WEAPON_BULLPUPSHOTGUN`] = {object = `w_sg_bullpupshotgun`, item = 'WEAPON_BULLPUPSHOTGUN', rot = vector3(0,0,0)},
    [`WEAPON_BAT`] = {object = `w_me_bat`, item = 'WEAPON_BAT', rot = vector3(0,92.5,0)},
    [`WEAPON_ADVANCEDRIFLE`] = {object = `w_ar_advancedrifle`, item = 'WEAPON_ADVANCEDRIFLE', rot = vector3(0,0,0)},
    [`WEAPON_MINISMG`] = {object = `w_sb_minismg`, item = 'WEAPON_MINISMG', rot = vector3(0,0,0)},
    [`WEAPON_REVOLVER`] = {object = `w_pi_revolver`, item = 'WEAPON_REVOLVER', rot = vector3(0,0,0)},
    [`WEAPON_REVOLVER_MK2`] = {object = `w_pi_revolvermk2`, item = 'WEAPON_REVOLVER_MK2', rot = vector3(0,0,0)},
    [`WEAPON_APPISTOL`] = {object = `w_pi_appistol`, item = 'WEAPON_APPISTOL', rot = vector3(0,0,0)},
    [`WEAPON_SNSPISTOL`] = {object = `w_pi_sns_pistol`, item = 'WEAPON_SNSPISTOL', rot = vector3(0,0,0)},
    [`WEAPON_PISTOL_MK2`] = {object = `w_pi_pistolmk2`, item = 'WEAPON_PISTOL_MK2', rot = vector3(0,0,0)},
    [`WEAPON_COMBATPISTOL`] = {object = `w_pi_combatpistol`, item = 'WEAPON_COMBATPISTOL', rot = vector3(0,0,0)},
    [`WEAPON_STUNGUN`] = {object = `w_pi_stungun`, item = 'WEAPON_STUNGUN', rot = vector3(0,0,0)},
    [`WEAPON_PISTOL50`] = {object = `w_pi_pistol50`, item = 'WEAPON_PISTOL50', rot = vector3(0,0,0)},
    [`WEAPON_VINTAGEPISTOL`] = {object = `w_pi_vintage_pistol`, item = 'WEAPON_VINTAGEPISTOL', rot = vector3(0,0,0)},
    [`WEAPON_KNIFE`] = {object = `w_me_knife_01`, item = 'WEAPON_KNIFE', rot = vector3(0,0,0)},
    [`WEAPON_WRENCH`] = {object = `w_me_wrench`, item = 'WEAPON_WRENCH', rot = vector3(0,0,0)},
    [`WEAPON_FLASHLIGHT`] = {object = `w_me_flashlight`, item = 'WEAPON_FLASHLIGHT', rot = vector3(0,0,0)},
    [`WEAPON_MACHETE`] = {object = `w_me_machette_lr`, item = 'WEAPON_MACHETE', rot = vector3(0,0,0)},
    [`WEAPON_NIGHTSTICK`] = {object = `w_me_nightstick`, item = 'WEAPON_NIGHTSTICK', rot = vector3(0,0,0)},
}

local slots = {
    [1] = {
        pos = vec3(0.13, -0.19, -0.04), -- Center Of Back
        entity = nil,
        hash = nil,
        wep = nil
    },
    [2] = {
        pos = vec3(0.13, -0.15, -0.16), -- Center-Right
        entity = nil,
        hash = nil,
        wep = nil
    },
    [3] = {
        pos = vec3(0.13, -0.15, 0.07), -- Center-Left
        entity = nil,
        hash = nil,
        wep = nil
    },
}

local function clearSlot(i)
    DetachEntity(slots[i].entity)
    DeleteEntity(slots[i].entity)
    slots[i].entity = nil
    slots[i].hash = nil
    slots[i].wep = nil
end

local function removeFromSlot(hash)
    if Weapons[hash] == nil then return end
    local whatItem = Weapons[hash].item
    local count = ox_inventory:Search(2, whatItem)
    for i = 1, #slots do
        if slots[i].hash == hash then
            if not count or count <= 0 or hash == curWeapon then
                clearSlot(i)
            end
        end
    end
end

local function removeWeapon(hash)
    if Weapons[hash] then
        removeFromSlot(hash)
    end
end

local function removeFromInv(hash)
    removeFromSlot(hash)
end

local function checkForSlot(hash)
    for i = 1, #slots do
        if slots[i].hash == hash then return false end
    end
    for i = 1, #slots do
        local slot = slots[i]
        if not slot.entity then
            return i
        end
    end
    return false
end

local function checkWeapon(object)
    local meleeList = {'WEAPON_KNIFE', 'WEAPON_WRENCH'}
    local pistolList = {'WEAPON_PISTOL', 'WEAPON_REVOLVER', 'WEAPON_APPISTOL', 'WEAPON_SNSPISTOL', 'WEAPON_PISTOL_MK2', 'WEAPON_STUNGUN', 'WEAPON_PISTOL50'}
    local pistol2List = {'WEAPON_REVOLVER_MK2', 'WEAPON_COMBATPISTOL', 'WEAPON_VINTAGEPISTOL'}
    local smgList = {'WEAPON_MINISMG', 'WEAPON_SMG_MK2'}
    local longList = {'WEAPON_BULLPUPSHOTGUN', 'WEAPON_HEAVYSNIPER', 'WEAPON_ASSAULTRIFLE', 'WEAPON_CARBINERIFLE', 'WEAPON_SPECIALCARBINE', 'WEAPON_SNIPERRIFLE', 'WEAPON_BULLPUPRIFLE'}

    local result = nil
    if exports['qb-core']:InArray(meleeList, object) then
        result = {}
        result.bone = 24818
        result.pos = { x = -0.22, y = -0.11, z = -0.13}
        result.rot = { x = 0.0, y = 0.0, z = 0.0}
    elseif object == 'WEAPON_MACHETE' then
        result = {}
        result.bone = 58271
        result.pos = { x = -0.01, y = 0.1, z = -0.07}
        result.rot = { x = -55.0, y = 160.0, z = 0.0}
    elseif object == 'WEAPON_NIGHTSTICK' then
        result = {}
        result.bone = 24818
        result.pos = { x = -0.15, y = 0.1, z = 0.17}
        result.rot = { x = -100.0, y = -100.0, z = 10.0}
    elseif object == 'WEAPON_FLASHLIGHT' then
        result = {}
        result.bone = 24818
        result.pos = { x = -0.2, y = 0.14, z = 0.12}
        result.rot = { x = 0.0, y = -90.0, z = 0.0}
    elseif exports['qb-core']:InArray(pistolList, object) then
        result = {}
        result.bone = 24816
        result.pos = { x = -0.09, y = 0.0, z = -0.23}
        result.rot = { x = 90.0, y = 20.0, z = 180.0}
    elseif exports['qb-core']:InArray(pistol2List, object) then
        result = {}
        result.bone = 24818
        result.pos = { x = -0.2, y = -0.1, z = -0.03}
        result.rot = { x = 180.0, y = 160.0, z = 0.0}
    elseif exports['qb-core']:InArray(smgList, object) then
        result = {}
        result.bone = 24818
        result.pos = { x = 0.1, y = -0.15, z = -0.0}
        result.rot = { x = 0.0, y = 180.0, z = 0.0}
    elseif object == 'WEAPON_SMG' then
        result = {}
        result.bone = 24818
        result.pos = { x = 0.1, y = -0.2, z = -0.15}
        result.rot = { x = 90.0, y = 180.0, z = 0.0}
    elseif object == 'SKATEBOARD' then
        result = {}
        result.bone = 24818
        result.pos = { x = -0.22, y = -0.08, z = -0.00}
        result.rot = { x = 0.0, y = 90.0, z = -90.0}
    elseif object == 'black_money' then
        result = {}
        result.bone = 24818
        result.pos = { x = -0.4, y = -0.17, z = -0.12}
        result.rot = { x = 0.0, y = 90.0, z = 0.0}
    elseif exports['qb-core']:InArray(longList, object) then
        result = {}
        result.bone = 24818
        result.pos = { x = 0.2, y = -0.2, z = 0.15}
        result.rot = { x = 90.0, y = 180.0, z = 0.0}
    end

    return result
end

local function putOnBack(hash)
    local whatSlot = checkForSlot(hash)
    if whatSlot then
        curWeapon = nil
        local object = Weapons[hash].object
        local item = Weapons[hash].item
        lib.requestModel(object, 20000)
        local coords = GetEntityCoords(ped)
        local prop = CreateObject(object, coords.x, coords.y, coords.z,  true,  true, true)
        slots[whatSlot].entity = prop
        slots[whatSlot].hash = hash
        slots[whatSlot].wep = item
        local checkWP = checkWeapon(item)
        if checkWP ~= nil then
            AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, checkWP.bone), checkWP.pos.x, checkWP.pos.y, checkWP.pos.z, checkWP.rot.x, checkWP.rot.y, checkWP.rot.z, true, true, false, true, 2, true)
        else
            AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 24816), slots[whatSlot].pos.x, slots[whatSlot].pos.y, slots[whatSlot].pos.z, Weapons[hash].rot.x, Weapons[hash].rot.y, Weapons[hash].rot.z, true, true, false, true, 2, true)
        end
    end
end

AddEventHandler('ox_inventory:currentWeapon', function(data)
    if data then
        if Weapons[data.hash] then
            putOnBack(curWeapon)
            curWeapon = data.hash
            removeWeapon(data.hash)
        end
    else
        if curWeapon then
            putOnBack(curWeapon)
        end
    end
end)

AddEventHandler('ox_inventory:updateInventory', function(changes)
    for k, v in pairs(changes) do
        if type(v) == 'table' then
            local hash = joaat(v.name)
            if Weapons[hash] then
                if curWeapon ~= hash then
                    putOnBack(hash)
                else
                    removeFromInv(hash)
                end
            end
        end
        if type(v) == 'boolean' then
            for i = 1, #slots do
                local count = ox_inventory:Search(2, slots[i].wep)
                if not count or count <= 0 then
                    removeFromInv(slots[i].hash)
                end
            end
        end
    end
end)

lib.onCache('ped', function(value)
    ped = value
end)

local function refreshWeapons()
    if GetResourceState('ox_inventory') ~= 'started' then return end
    Wait(2000)
    for i = 1, #slots do
        clearSlot(i)
    end
    Wait(100)
    for k, v in pairs(Weapons) do
        local count = ox_inventory:Search(2, v.item)
        if count and count >= 1 then
            putOnBack(k)
        end
    end
end

exports('refreshWeapons', refreshWeapons)