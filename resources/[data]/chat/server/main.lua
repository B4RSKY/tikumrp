local Config = require "config.config"
Database = {}

CreateThread(function()
    local file = json.decode(LoadResourceFile(GetCurrentResourceName(), "database/index.json"))
    if file then
        for index, data in pairs(file) do
            Database[index] = data
        end
    end
end)

while (not Framework) do
    Citizen.Wait(1000)
end

RegisterNetEvent('chat:server:sendMessage', function(data)
    local src = source
    local xPlayer = Framework.GetPlayer(src)

    if xPlayer then
        local firstname, lastname = Framework.GetPlayerName(src)

        if data.category == 'do' or data.category == 'me' then
            local Players = GetPlayers()

            if #Players <= 0 then
                return
            end

            for _, player in ipairs(Players) do
                local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(player)))
                if distance < 10.0 then
                    TriggerClientEvent('chat:client:sendMessage', player, {
                        source = src,
                        fullname = data.mask and 'Anonymous' or (firstname .. ' ' .. lastname),
                        category = data.category,
                        message = data.message,
                        isImage = false,
                        isDice = false,
                        isRPS = false,
                    })
                end
            end
        elseif data.category == 'ooc' then
            local Players = GetPlayers()

            if #Players <= 0 then
                return
            end

            for _, player in ipairs(Players) do
                local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(player)))
                if distance < 10.0 then
                    TriggerClientEvent('chat:client:sendMessage', player, {
                        source = src,
                        fullname = firstname .. ' ' .. lastname,
                        category = data.category,
                        message = data.message,
                        isImage = false,
                        isDice = false,
                        isRPS = false,
                    })
                end
            end
        elseif data.category == 'pm' then
            local tPlayer = Framework.GetPlayer(data.targetPlayer)

            if tPlayer then
                TriggerClientEvent('chat:client:sendMessage', tPlayer.source, {
                    fullname = firstname .. ' ' .. lastname,
                    category = data.category,
                    message = data.message,
                    isImage = false,
                    isDice = false,
                })
                TriggerClientEvent('chat:client:sendMessage', src, {
                    fullname = firstname .. ' ' .. lastname,
                    category = data.category,
                    message = data.message,
                    isImage = false,
                    isDice = false,
                    isRPS = false,
                })
            else
            end
        elseif data.category == 'admin' then
            local Players = GetPlayers()

            if #Players <= 0 then
                return
            end

            for _, player in ipairs(Players) do
                if IsPlayerAceAllowed(tonumber(player), 'admin') then
                    TriggerClientEvent('chat:client:sendMessage', player, {
                        fullname = firstname .. ' ' .. lastname,
                        category = data.category,
                        message = data.message,
                        isImage = false,
                        isDice = false,
                        isRPS = false,
                    })
                end
            end
        elseif data.category == 'server' then
            local Players = GetPlayers()

            if #Players <= 0 then
                return
            end

            for _, player in ipairs(Players) do
                TriggerClientEvent('chat:client:sendMessage', player, {
                    fullname = firstname .. ' ' .. lastname,
                    category = data.category,
                    message = data.message,
                    isImage = false,
                    isDice = false,
                    isRPS = false,
                })
            end
        elseif data.category == 'dice' then
            local Players = GetPlayers()

            if #Players <= 0 then
                return
            end

            for _, player in ipairs(Players) do
                local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(player)))
                if distance < 10.0 then
                    TriggerClientEvent('chat:client:sendMessage', player, {
                        fullname = data.mask and 'Anonymous' or (firstname .. ' ' .. lastname),
                        category = data.category,
                        message = data.message,
                        isImage = false,
                        isDice = true,
                        isRPS = false,
                    })
                end
            end
        elseif data.category == 'rps' then
            local Players = GetPlayers()

            if #Players <= 0 then
                return
            end

            for _, player in ipairs(Players) do
                local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(player)))
                if distance < 10.0 then
                    TriggerClientEvent('chat:client:sendMessage', player, {
                        fullname = data.mask and 'Anonymous' or (firstname .. ' ' .. lastname),
                        category = data.category,
                        message = data.message,
                        hand = data.hand or 'paper',
                        isImage = false,
                        isDice = false,
                        isRPS = true,
                    })
                end
            end
        elseif data.category == 'img' then
            local Players = GetPlayers()

            if #Players <= 0 then
                return
            end

            for _, player in ipairs(Players) do
                local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(player)))
                if distance < 10.0 then
                    TriggerClientEvent('chat:client:sendMessage', player, {
                        source = src,
                        fullname = data.mask and 'Anonymous' or (firstname .. ' ' .. lastname),
                        category = data.category,
                        message = data.message,
                        isImage = data.isImage,
                        isDice = false,
                        isRPS = false,
                    })
                end
            end
        elseif Config.JobChat[data.category] then
            local job, label, grade_label, grade = Framework.GetPlayerJob(src)
            local jobChat = Config.JobChat[job]

            if jobChat and jobChat.job == data.category and jobChat.status then
                TriggerClientEvent('chat:client:sendMessage', -1, {
                    fullname = firstname .. ' ' .. lastname,
                    category = data.category,
                    message = data.message,
                    isImage = false,
                    isDice = false,
                    isRPS = false,
                })
            end
        elseif Config.GangChat[data.category] then
            local gang = Framework.GetPlayerGang(src)
            local gangChat = Config.GangChat[gang]

            if gangChat and gangChat.gang == data.category and gangChat.status then
                local gangPlayers = Framework.GetPlayersByGang(gang)
                if #gangPlayers > 0 then
                    for _, gangPlayer in ipairs(gangPlayers) do
                        TriggerClientEvent('chat:client:sendMessage', gangPlayer, {
                            fullname = firstname .. ' ' .. lastname,
                            category = data.category,
                            message = data.message,
                            isImage = false,
                            isDice = false,
                            isRPS = false,
                        })
                    end
                end
            end
        elseif data.category == 'tweet' then
            local Players = GetPlayers()

            if #Players <= 0 then
                return
            end

            for _, player in ipairs(Players) do
                TriggerClientEvent('chat:client:sendMessage', player, {
                    fullname = firstname .. ' ' .. lastname,
                    category = data.category,
                    message = data.message,
                    isImage = false,
                    isDice = false,
                    isRPS = false,
                })
            end
        elseif data.category == 'yellowpages' then
            local Players = GetPlayers()

            if #Players <= 0 then
                return
            end

            for _, player in ipairs(Players) do
                TriggerClientEvent('chat:client:sendMessage', player, {
                    fullname = firstname .. ' ' .. lastname,
                    category = data.category,
                    message = data.message,
                    isImage = false,
                    isDice = false,
                    isRPS = false,
                })
            end
        elseif data.category == 'charinfo' then
            local index, gender = Framework.GetGender(src)
            local job, label, grade_label, grade = Framework.GetPlayerJob(src)

            local message = ''
            message = 'Birthdate: ' .. Framework.GetPlayerDob(src) .. '\n'
            message = message .. 'Gender: ' .. gender .. '\n'
            message = message .. 'Job Label: ' .. label .. '\n'
            message = message .. 'Job Grade: ' .. grade_label .. '\n'
            message = message .. 'Bank: ' .. Framework.GetAccountBalance(src, 'bank') .. '\n'
            message = message .. 'Cash: ' .. Framework.GetAccountBalance(src, 'money') .. '\n'

            TriggerClientEvent('chat:client:sendMessage', src, {
                fullname = firstname .. ' ' .. lastname,
                category = data.category,
                message = message,
                isImage = false,
                isDice = false,
                isRPS = false,
            })
        elseif data.category == 'report' then
            local Players = GetPlayers()

            if #Players <= 0 then
                return
            end

            for _, player in ipairs(Players) do
                if IsPlayerAceAllowed(tonumber(player), 'admin') then
                    if tonumber(src) ~= tonumber(player) then
                        TriggerClientEvent('chat:client:sendMessage', player, {
                            fullname = firstname .. ' ' .. lastname .. ' [ '.. src .. ']',
                            category = data.category,
                            message = data.message,
                            isImage = false,
                            isDice = false,
                            isRPS = false,
                        })
                    end
                end
            end

            TriggerClientEvent('chat:client:sendMessage', src, {
                fullname = firstname .. ' ' .. lastname,
                category = data.category,
                message = data.message,
                isImage = false,
                isDice = false,
                isRPS = false,
            })
        elseif data.category == 'reportreply' then
            if not data.targetPlayer or type(data.targetPlayer) ~= 'number' or data.targetPlayer == src then
                return
            end

            local tPlayer = Framework.GetPlayer(data.targetPlayer)
            if tPlayer then
                TriggerClientEvent('chat:client:sendMessage', data.targetPlayer, {
                    fullname = firstname .. ' ' .. lastname,
                    category = data.category,
                    message = data.message,
                    isImage = false,
                    isDice = false,
                    isRPS = false,
                })

                TriggerClientEvent('chat:client:sendMessage', src, {
                    fullname = firstname .. ' ' .. lastname,
                    category = data.category,
                    message = data.message,
                    isImage = false,
                    isDice = false,
                    isRPS = false,
                })
            end
        elseif data.category == 'custom' then
            TriggerClientEvent('chat:client:sendMessage', src, {
                category = data.category,
                message = data.message,
                isImage = false,
                isDice = false,
                isRPS = false,
            })
        end
    end
end)

-- local proximity = 20.0 
-- RegisterNetEvent('chat:server:writingText', function(bool)
--     local src = source
--     local sourceCoords = GetEntityCoords(GetPlayerPed(tostring(src)))


--     if not sourceCoords then return end
--     local players = QBCore.Functions.GetPlayers()

--     for _, playerId in ipairs(players) do
--         if playerId ~= src then
--             local targetPed = GetPlayerPed(tostring(playerId))

--             if targetPed and targetPed ~= 0 then
--                 local targetCoords = GetEntityCoords(targetPed)
                
--                 if #(sourceCoords - targetCoords) < proximity then
--                     TriggerClientEvent('chat:client:writingText', playerId, src, bool)
--                 end
--             end
--         end
--     end
-- end)

local proximity = 20.0 
RegisterNetEvent('chat:server:writingText', function(bool)
    local src = source
    local sourceCoords = GetEntityCoords(GetPlayerPed(tostring(src)))

    if not sourceCoords then return end

    for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
        local targetPed = GetPlayerPed(tostring(playerId))

        if targetPed and targetPed ~= 0 then
            if playerId == src or #(sourceCoords - GetEntityCoords(targetPed)) < proximity then
                TriggerClientEvent('chat:client:writingText', playerId, src, bool)
            end
        end
    end
end)