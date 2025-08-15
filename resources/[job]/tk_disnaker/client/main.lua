local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local currentBlips = {}
local isLoggedIn = false
local ts = {ss = TriggerServerEvent}

disnaker = function(jenis, tipe, kurang, dapat)
    ts.ss('tk-disnaker:status', {jenis = 'item', model = 'add', meta = {jenis = jenis, tipe = tipe, kurang = tonumber(kurang), dapat = tonumber(dapat)}})
    return
end

-- =====================================================
-- BLIP UTILITY
-- =====================================================
local function hasRequiredJob(jobList)
    if not jobList or jobList == false then
        return true
    end
    
    if not PlayerData.job then return false end
    
    for _, job in ipairs(jobList) do
        if PlayerData.job.name == job then
            return true
        end
    end
    return false
end

local function createBlip(blipData)
    local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
    
    SetBlipSprite(blip, blipData.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipColour(blip, blipData.color)
    SetBlipScale(blip, blipData.scale)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipData.name)
    EndTextCommandSetBlipName(blip)
    
    return blip
end

local function removeAllBlips()
    for _, blip in pairs(currentBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    currentBlips = {}
end

local function createJobBlips()
    if not isLoggedIn then
        return
    end
    
    for i, blipData in ipairs(Config.Blips) do
        if hasRequiredJob(blipData.jobs) then
            local blip = createBlip(blipData)
            currentBlips[i] = blip
        end
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
    Wait(1000)
    createJobBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    PlayerData = {}
    removeAllBlips()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
    
    if isLoggedIn then
        removeAllBlips()
        createJobBlips()
    end
end)

RegisterNetEvent('tk-disnaker:blip:refresh', function()
    if isLoggedIn then
        removeAllBlips()
        createJobBlips()
    end
end)

--Untuk Export
exports('addBlip', function(blipData)
    if not blipData or not blipData.coords or not blipData.jobs then
        return false
    end

    blipData.sprite = blipData.sprite or 1
    blipData.color = blipData.color or 0
    blipData.scale = blipData.scale or 1.0
    blipData.shortRange = blipData.shortRange or true
    blipData.name = blipData.name or "Unnamed Location"

    table.insert(Config.Blips, blipData)
    
    if isLoggedIn and hasRequiredJob(blipData.jobs) then
        local blip = createBlip(blipData)
        currentBlips[#Config.Blips] = blip
    end
    
    return true
end)

exports('removeBlip', function(blipName)
    for i, blipData in ipairs(Config.Blips) do
        if blipData.name == blipName then
            if currentBlips[i] and DoesBlipExist(currentBlips[i]) then
                RemoveBlip(currentBlips[i])
                currentBlips[i] = nil
            end
            table.remove(Config.Blips, i)
            return true
        end
    end
    return false
end)

exports('getBlipsConfig', function()
    return Config.Blips
end)

exports('getActiveBlips', function()
    return currentBlips
end)

exports('refreshBlips', function()
    if isLoggedIn then
        removeAllBlips()
        createJobBlips()
    end
end)

exports('hasJob', function(jobName)
    if not PlayerData.job then return false end
    return PlayerData.job.name == jobName
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        removeAllBlips()
    end
end)