ClientFuncs = {}

local ESX = nil
local QBCore = nil
local cachedTheme = nil
local previousArmor = GetPedArmour(PlayerPedId())

-- Detecteer framework
CreateThread(function()
    Wait(5000)
    if GetResourceState("qb-core") == "started" then
        QBCore = exports["qb-core"]:GetCoreObject()
    elseif GetResourceState("es_extended") == "started" then
        ESX = exports["es_extended"]:getSharedObject()
    end
end)

-- Armor bijhouden
local function UpdatePreviousArmor()
    previousArmor = GetPedArmour(PlayerPedId())
end

-- Bepaal gender
local function GetGender(ped)
    local model = GetEntityModel(ped)
    if model == 1885233650 then
        return "male"
    elseif model == -1667301416 then
        return "female"
    end
    return "male"
end

-- Theme ophalen
local function GetTheme()
    if not cachedTheme then
        cachedTheme = lib.callback.await("akilla-inventory:getTheme", 200)
    end
    return cachedTheme
end

local function ApplyTheme(theme)
    if theme then
        SendNUIMessage({
            action = "setTheme",
            data = theme
        })
    end
end

-- Check of item een backpack is
local function IsBackpack(itemName)
    if not itemName then return false end

    local backpacks = {
        "backpack", "small_backpack", "medium_backpack", "large_backpack",
        "tactical_backpack", "school_backpack", "hiking_backpack",
        "duffel_bag", "sports_bag"
    }

    local lower = string.lower(itemName)
    if string.find(lower, "backpack") or string.find(lower, "bag") then
        return true
    end

    for _, v in ipairs(backpacks) do
        if itemName == v then
            return true
        end
    end

    local item = exports.ox_inventory:Items(itemName)
    if item and item.backpack == true then
        return true
    end

    return false
end

-- Inventory instellingen
function ClientFuncs.SetupInventorySettings()
    local settings = {
        gender = GetGender(cache.ped),
        SpecialSlot = Config.UtilitySlots,
        blacklistedItems = Config.BackpackBlacklist
    }
    SendNUIMessage({
        action = "setupInventorySettings",
        data = settings
    })
end

-- Player license ophalen
function ClientFuncs.GetPlayerLicense()
    local fw = GlobalState.fw
    if fw == "esx" then
        return lib.callback.await("akilla-inventory:ESX:GetLicense", false)
    elseif fw == "qb" then
        return QBCore.Functions.GetPlayerData().cid
    elseif fw == "qbx" then
        return QBX.PlayerData.cid
    end
end

-- Backpack check
function ClientFuncs.CheckForBackpack()
    local items = exports.ox_inventory:GetPlayerItems()
    if not items then
        LocalPlayer.state:set("backpack", nil, true)
        TriggerServerEvent("akilla-inventory:SyncBackpackClothes", nil)
        return false
    end

    local firstItem = items[1]
    if firstItem and IsBackpack(firstItem.name) then
        if not firstItem.metadata then firstItem.metadata = {} end
        if not firstItem.metadata.id then
            firstItem.metadata.id = "bp_" .. GetPlayerServerId(PlayerId()) ..
                                    "_" .. math.random(100000, 999999) ..
                                    "_" .. GetGameTimer()
        end

        local newState = {
            use = true,
            id = firstItem.metadata.id,
            itemName = firstItem.name
        }

        LocalPlayer.state:set("backpack", newState, true)
        TriggerServerEvent("akilla-inventory:SyncBackpackClothes", firstItem.metadata.id)
        return true
    end

    LocalPlayer.state:set("backpack", nil, true)
    TriggerServerEvent("akilla-inventory:SyncBackpackClothes", nil)
    return false
end

-- Events
RegisterNetEvent("akilla-inventory:SetBackpackClothes", function(src, hasBackpack)
    if not Config.BackpackProp.Enabled then return end

    local ped = GetPlayerPed(GetPlayerFromServerId(src))
    if not DoesEntityExist(ped) then return end

    local gender = GetGender(ped)
    if not hasBackpack then
        ClearPedProp(ped, 5)
        SetPedComponentVariation(ped, 5, 0, 0, 2)
    else
        local config = Config.BackpackProp[gender]
        SetPedComponentVariation(ped, 5, config.DrawableID, config.Texture or 0, 2)
    end
end)

RegisterNetEvent("akilla-inventory:themeChanged", function(theme)
    cachedTheme = theme
    ApplyTheme(theme)
end)

-- Command
RegisterCommand("previewtheme", function(_, args)
    if args[1] then
        TriggerServerEvent("akilla-inventory:changeTheme", args[1])
    else
        lib.notify({
            type = "info",
            description = "Usage: /previewtheme [theme_name]"
        })
    end
end, false)
