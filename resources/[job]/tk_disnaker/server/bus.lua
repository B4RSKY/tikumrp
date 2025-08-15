-- -- server.lua
-- local QBCore = exports['qb-core']:GetCoreObject()

-- -- Callback for checkpoint rewards
-- QBCore.Functions.CreateCallback('bus-job:checkpoint-reward', function(source, cb, amount)
--     local Player = QBCore.Functions.GetPlayer(source)
    
--     if not Player then
--         cb(false)
--         return
--     end
    
--     -- Add money to player
--     Player.Functions.AddMoney('cash', amount, 'Bus Job Checkpoint')
    
--     -- Optional: Add experience or reputation system here
--     -- You can also add items as rewards
    
--     cb(true)
-- end)

-- -- Event for final route completion
-- RegisterNetEvent('bus-job:complete-route', function(totalAmount, routeKey)
--     local src = source
--     local Player = QBCore.Functions.GetPlayer(src)
    
--     if not Player then
--         return
--     end
    
--     -- Add final payment
--     Player.Functions.AddMoney('cash', totalAmount, 'Bus Job Route Completion')
    
--     -- Log the completion (optional)
--     print(string.format("Player %s (%s) completed bus route '%s' and earned $%d", 
--         Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
--         Player.PlayerData.citizenid,
--         routeKey,
--         totalAmount
--     ))
    
--     -- Optional: Add to player stats/achievements
--     local currentBusJobStats = Player.PlayerData.metadata.busjob or {
--         routes_completed = 0,
--         total_earned = 0,
--         favorite_route = nil
--     }
    
--     currentBusJobStats.routes_completed = currentBusJobStats.routes_completed + 1
--     currentBusJobStats.total_earned = currentBusJobStats.total_earned + totalAmount
--     currentBusJobStats.favorite_route = routeKey
    
--     Player.Functions.SetMetaData('busjob', currentBusJobStats)
    
--     -- Optional: Send webhook to Discord for logging
--     -- SendDiscordWebhook(Player, routeKey, totalAmount)
-- end)

-- -- Optional: Bonus system for consecutive routes
-- RegisterNetEvent('bus-job:check-bonus', function(consecutiveRoutes)
--     local src = source
--     local Player = QBCore.Functions.GetPlayer(src)
    
--     if not Player then
--         return
--     end
    
--     local bonusAmount = 0
    
--     if consecutiveRoutes >= 3 then
--         bonusAmount = 1000
--     elseif consecutiveRoutes >= 5 then
--         bonusAmount = 2000
--     elseif consecutiveRoutes >= 10 then
--         bonusAmount = 5000
--     end
    
--     if bonusAmount > 0 then
--         Player.Functions.AddMoney('cash', bonusAmount, 'Bus Job Consecutive Bonus')
--         TriggerClientEvent('QBCore:Notify', src, 
--             string.format('Bonus! %d rute berturut-turut: +$%d', consecutiveRoutes, bonusAmount), 
--             'success', 5000
--         )
--     end
-- end)

-- -- Command for admins to check player bus job stats
-- QBCore.Commands.Add('checkbusjob', 'Check player bus job statistics (Admin Only)', {{name = 'id', help = 'Player Server ID'}}, true, function(source, args)
--     local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    
--     if not Player then
--         TriggerClientEvent('QBCore:Notify', source, 'Player not found!', 'error')
--         return
--     end
    
--     local stats = Player.PlayerData.metadata.busjob or {routes_completed = 0, total_earned = 0}
    
--     TriggerClientEvent('chat:addMessage', source, {
--         color = {0, 255, 0},
--         multiline = true,
--         args = {"Bus Job Stats", string.format(
--             "Player: %s %s\nRoutes Completed: %d\nTotal Earned: $%d\nFavorite Route: %s",
--             Player.PlayerData.charinfo.firstname,
--             Player.PlayerData.charinfo.lastname,
--             stats.routes_completed,
--             stats.total_earned,
--             stats.favorite_route or "None"
--         )}
--     })
-- end, 'admin')

-- -- Optional: Reset player bus job stats
-- QBCore.Commands.Add('resetbusjob', 'Reset player bus job statistics (Admin Only)', {{name = 'id', help = 'Player Server ID'}}, true, function(source, args)
--     local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    
--     if not Player then
--         TriggerClientEvent('QBCore:Notify', source, 'Player not found!', 'error')
--         return
--     end
    
--     Player.Functions.SetMetaData('busjob', {
--         routes_completed = 0,
--         total_earned = 0,
--         favorite_route = nil
--     })
    
--     TriggerClientEvent('QBCore:Notify', source, 'Bus job stats reset successfully!', 'success')
-- end, 'admin')

-- -- Optional: Discord Webhook Function
-- --[[
-- function SendDiscordWebhook(Player, routeKey, amount)
--     local webhook = "YOUR_DISCORD_WEBHOOK_URL_HERE"
--     local embed = {
--         {
--             color = 3066993,
--             title = "**Bus Job Completed**",
--             description = string.format(
--                 "**Player:** %s %s (%s)\n**Route:** %s\n**Amount Earned:** $%d\n**Time:** %s",
--                 Player.PlayerData.charinfo.firstname,
--                 Player.PlayerData.charinfo.lastname,
--                 Player.PlayerData.citizenid,
--                 routeKey,
--                 amount,
--                 os.date("%Y-%m-%d %H:%M:%S")
--             ),
--             footer = {
--                 text = "Bus Job System",
--                 icon_url = "https://cdn-icons-png.flaticon.com/512/3774/3774299.png"
--             },
--             timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
--         }
--     }
    
--     PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
--         username = "Bus Job Bot",
--         embeds = embed
--     }), { ['Content-Type'] = 'application/json' })
-- end
-- --]]

-- -- Optional: Add items to players (uniform, etc.)
-- RegisterNetEvent('bus-job:give-uniform', function()
--     local src = source
--     local Player = QBCore.Functions.GetPlayer(src)
    
--     if not Player then
--         return
--     end
    
--     -- Give uniform items
--     Player.Functions.AddItem('bus_uniform', 1)
--     TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['bus_uniform'], "add")
-- end)

-- -- Optional: Vehicle spawn with proper ownership
-- RegisterNetEvent('bus-job:spawn-bus', function(coords, routeKey)
--     local src = source
--     local Player = QBCore.Functions.GetPlayer(src)
    
--     if not Player then
--         return
--     end
    
--     -- Create vehicle with proper ownership
--     local plate = "BUS"..math.random(1000, 9999)
--     local vehicleProps = {
--         model = Config.BusHash,
--         plate = plate,
--         coords = coords,
--         warp = true,
--         fuel = 100
--     }
    
--     TriggerClientEvent('bus-job:receive-bus', src, vehicleProps)
-- end)