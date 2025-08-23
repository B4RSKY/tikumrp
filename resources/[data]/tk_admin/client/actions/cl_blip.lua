local isPlayerIdsEnabled = false
local playerGamerTags = {}
local distanceToCheck = 150

local GamerTagCompsEnum = {
    GamerName = 0,
    CrewTag = 1,
    HealthArmour = 2,
    BigText = 3,
    AudioIcon = 4,
    UsingMenu = 5,
    PassiveMode = 6,
    WantedStars = 7,
    Driver = 8,
    CoDriver = 9,
    Tagged = 12,
    GamerNameNearby = 13,
    Arrow = 14,
    Packages = 15,
    InvIfPedIsFollowing = 16,
    RankText = 17,
    Typing = 18
}

local function cleanAllGamerTags()
    for _, v in pairs(playerGamerTags) do
        if IsMpGamerTagActive(v.gamerTag) then
            RemoveMpGamerTag(v.gamerTag)
        end
    end
    playerGamerTags = {}
end

local function setGamerTag(targetTag, pid)
    SetMpGamerTagVisibility(targetTag, GamerTagCompsEnum.GamerName, 1)
    SetMpGamerTagHealthBarColor(targetTag, 129)
    SetMpGamerTagAlpha(targetTag, GamerTagCompsEnum.HealthArmour, 255)
    SetMpGamerTagVisibility(targetTag, GamerTagCompsEnum.HealthArmour, 1)
    SetMpGamerTagAlpha(targetTag, GamerTagCompsEnum.AudioIcon, 255)
    if NetworkIsPlayerTalking(pid) then
        SetMpGamerTagVisibility(targetTag, GamerTagCompsEnum.AudioIcon, true)
        SetMpGamerTagColour(targetTag, GamerTagCompsEnum.AudioIcon, 12) --HUD_COLOUR_YELLOW
        SetMpGamerTagColour(targetTag, GamerTagCompsEnum.GamerName, 12) --HUD_COLOUR_YELLOW
    else
        SetMpGamerTagVisibility(targetTag, GamerTagCompsEnum.AudioIcon, false)
        SetMpGamerTagColour(targetTag, GamerTagCompsEnum.AudioIcon, 0)
        SetMpGamerTagColour(targetTag, GamerTagCompsEnum.GamerName, 0)
    end
end

local function clearGamerTag(targetTag)
    SetMpGamerTagVisibility(targetTag, GamerTagCompsEnum.GamerName, 0)
    SetMpGamerTagVisibility(targetTag, GamerTagCompsEnum.HealthArmour, 0)
    SetMpGamerTagVisibility(targetTag, GamerTagCompsEnum.AudioIcon, 0)
end

local function showGamerTags()
    local curCoords = GetEntityCoords(PlayerPedId())
    local allActivePlayers = GetActivePlayers()

    for _, pid in ipairs(allActivePlayers) do
        local targetPed = GetPlayerPed(pid)
        if not playerGamerTags[pid] or not IsMpGamerTagActive(playerGamerTags[pid].gamerTag) then
            local playerName = string.sub(GetPlayerName(pid) or 'unknown', 1, 75)
            local playerStr = '[' .. GetPlayerServerId(pid) .. ']' .. ' ' .. playerName
            playerGamerTags[pid] = {
                gamerTag = CreateFakeMpGamerTag(targetPed, playerStr, false, false, 0),
                ped = targetPed
            }
        end
        local targetTag = playerGamerTags[pid].gamerTag

        local targetPedCoords = GetEntityCoords(targetPed)
        if #(targetPedCoords - curCoords) <= distanceToCheck then
            setGamerTag(targetTag, pid)
        else
            clearGamerTag(targetTag)
        end
    end
end

local function createGamerTagThread()
    CreateThread(function()
        while isPlayerIdsEnabled do
            showGamerTags()
            Wait(250)
        end
        cleanAllGamerTags()
    end)
end

function toggleShowPlayerIDs(enabled)
    isPlayerIdsEnabled = enabled
    if isPlayerIdsEnabled then
        QBCore.Functions.Notify('ADMIN', 'Player names activated', 'success')
        createGamerTagThread()
    else
        QBCore.Functions.Notify('ADMIN', 'Player names deactived', 'error')
    end
end

RegisterNetEvent('admin:client:PlayerNames', function()
    -- if not IsPlayerAdmin() then return end
    toggleShowPlayerIDs(not isPlayerIdsEnabled)
end)

CreateThread(function()
    local sleep = 150
    while true do
        if isPlayerIDActive then
            showGamerTags()
            sleep = 50
        else
            sleep = 500
        end
        Wait(sleep)
    end
end)

-- Player Blips
local BlipsEnabled, BlipData = false, {}
local AllPlayerBlips = {}
local BlipColors = {
    ['police'] = 3,
    ['mechanic'] = 43,
    ['pemerintah'] = 24,
    ['pedagang'] = 17,
    ['admin'] = 5,
    ['ambulance'] = 6,
    ['badside1'] = 27,
    ['badside2'] = 27,
    ['badside3'] = 27,
    ['badside4'] = 27,
    ['badside5'] = 27,
    ['badside6'] = 27,
    ['badside7'] = 27,
    ['badside8'] = 27,
    ['badside9'] = 27,
    ['badside10'] = 27,
    ['badside11'] = 27,
    ['badside12'] = 27,
    ['badside13'] = 27,
    ['badside14'] = 27,
    ['badside15'] = 27,
    ['badside16'] = 27,
    ['badside17'] = 27,
    ['badside18'] = 27,
    ['badside19'] = 27,
    ['badside20'] = 27,
    ['badside21'] = 27,
    ['badside22'] = 27,
    ['badside23'] = 27,
    ['badside24'] = 27,
    ['badside25'] = 27
}

local function DeletePlayerBlips()
    if AllPlayerBlips ~= nil then
        for i = 1, #AllPlayerBlips do
            local Blip = AllPlayerBlips[i]
            RemoveBlip(Blip)
        end
        AllPlayerBlips = {}
    end
end

CreateThread(function()
    while true do
        if BlipsEnabled then
            if BlipData ~= nil then
                DeletePlayerBlips()
                for i=1, #BlipData do
                    local Blip = BlipData[i]
                    local playerId = GetPlayerFromServerId(Blip.id)
                    local PlayerBlip = nil
                    if playerId ~= -1 then
                        PlayerBlip = AddBlipForEntity(GetPlayerPed(playerId))
                    else
                        PlayerBlip = AddBlipForCoord(Blip.coords)
                    end
                    local color = BlipColors[Blip.job] or 0
                    SetBlipSprite(PlayerBlip, 1)
                    SetBlipColour(PlayerBlip, color)
                    SetBlipScale(PlayerBlip, 0.75)
                    SetBlipAsShortRange(PlayerBlip, true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentString('['..Blip.id..'] '..Blip.name..' ['..Blip.job..']')
                    EndTextCommandSetBlipName(PlayerBlip)
                    AllPlayerBlips[#AllPlayerBlips + 1] = PlayerBlip
                end    
            end
            Wait(10000)
            TriggerServerEvent('admin:server:refreshBlips')
        else
            if AllPlayerBlips ~= nil then
                DeletePlayerBlips()
            end
            Wait(1000)
        end
    end
end)

RegisterNetEvent('admin:client:PlayerBlips', function()
    -- if not IsPlayerAdmin() then return end
    BlipsEnabled = not BlipsEnabled
    TriggerServerEvent('admin:server:refreshBlips')
    if BlipsEnabled then
        QBCore.Functions.Notify('ADMIN', 'Player blips activated', 'success')
    else
        DeletePlayerBlips()
        QBCore.Functions.Notify('ADMIN', 'Player blips deactived', 'error')
    end
end)

RegisterNetEvent('admin:client:UpdatePlayerBlips', function(Data)
    BlipData = Data
end)

RegisterNUICallback('ShowNames', function(Data, Cb)
    TriggerEvent('admin:client:PlayerNames')
    Cb('Ok')
end)

RegisterNUICallback('ShowBlips', function(Data, Cb)
    TriggerEvent('admin:client:PlayerBlips')
    Cb('Ok')
end)