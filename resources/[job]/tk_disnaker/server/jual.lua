local QBCore = exports['qb-core']:GetCoreObject()

lib.callback.register('tk-disnaker:checkAdmin', function(source, cb)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if xPlayer then
        local hasPermission = QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'god')
        if hasPermission then
            return true
        else
            return false
        end
    else
        return false
    end
end)

lib.callback.register('tk-disnaker:main:getData', function(source)
    local categories = exports.oxmysql:executeSync('SELECT * FROM disnaker_categories', {})
    local items = exports.oxmysql:executeSync('SELECT * FROM disnaker_items', {})

    local data = {}
    for _, cat in ipairs(categories) do
        data[cat.category] = {}
    end

    for _, item in ipairs(items) do
        if not data[item.category] then
            data[item.category] = {}
        end
        table.insert(data[item.category], {
            item = item.item,
            price = item.price,
            stock = item.stock
        })
    end

    return data
end)

lib.callback.register('tk-disnaker:menu:addCategory', function(source, categoryName)
    exports.oxmysql:executeSync('INSERT IGNORE INTO disnaker_categories (category) VALUES (?)', { categoryName })
    return true
end)

lib.callback.register('tk-disnaker:menu:addItems', function(source, data)
    local query = 'INSERT INTO disnaker_items (category, item, price, stock) VALUES (?, ?, ?, ?)'
    exports.oxmysql:executeSync(query, { data.key, data.newItem, data.newPrice, data.stock })
    return true
end)

lib.callback.register('tk-disnaker:menu:deleteCategory', function(source, data)
    exports.oxmysql:executeSync('DELETE FROM disnaker_categories WHERE category = ?', { data.key })
    return true
end)

lib.callback.register('tk-disnaker:menu:editharga', function(source, data)
    exports.oxmysql:executeSync('UPDATE disnaker_items SET price = ? WHERE category = ? AND item = ?', { data.newPrice, data.key, data.item })
    return true
end)

lib.callback.register('tk-disnaker:menu:editStock', function(source, data)
    exports.oxmysql:executeSync('UPDATE disnaker_items SET stock = ? WHERE category = ? AND item = ?', { data.newStock, data.key, data.item })
    return true
end)

lib.callback.register('tk-disnaker:menu:delItems', function(source, data)
    exports.oxmysql:executeSync('DELETE FROM disnaker_items WHERE category = ? AND item = ?', { data.key, data.item })
    return true
end)

lib.callback.register('tk-disnaker:jual:jualItems', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)

    if Player.Functions.RemoveItem(data.item, data.input) then
        local moneyToAdd = data.input * tonumber(data.price)
        Player.Functions.AddMoney('cash', moneyToAdd)

        exports.oxmysql:executeSync('UPDATE disnaker_items SET stock = stock + ? WHERE category = ? AND item = ?', { data.input, data.key, data.item })

        local name = GetPlayerName(source)
		local steamhex = GetPlayerIdentifier(source)
		local communtiylogo = ""
		local logs = "https://discord.com/api/webhooks/1402215963235061772/CEbcd3_0NIt6uwRZVEyHFNd1WG2d2g5Lk9z7HAFakoKLysu1U-FAaYBuEhEQVOnw2s3E"
		local disnakerjual = {
            {
                ["color"] = "1942002",
                ["title"] = "Jual Disnaker",
                ["description"] = "**Player:** " .. name ..  
                                "\n**Steam Hex:** " .. steamhex .. 
                                "\n\n**Menjual:** " .. data.item..
                                "\n**Sebanyak:** " .. data.input..
                                "\n**Total Harga:** TK$" .. moneyToAdd,
                ["footer"] = {
                    ["text"] = "BAHTERA Logs • "..os.date("%a, %d %b %y at %H:%M%p"),
                    ["icon_url"] = communtiylogo,
                },
            }

        }
		PerformHttpRequest(logs, function(err, text, headers) end, 'POST', json.encode({username = "JUAL DISNAKER", embeds = disnakerjual}), { ['Content-Type'] = 'application/json' })
        return true
    else
        return false
    end
end)

lib.callback.register('tk-disnaker:beli:buyItems', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    local totalPrice = data.input * tonumber(data.price)
    local getMoney = Player.Functions.GetMoney('cash')

    if getMoney >= totalPrice then
        local result = exports.oxmysql:executeSync('SELECT stock FROM disnaker_items WHERE category = ? AND item = ?', { data.key, data.item })
        if result[1] and tonumber(result[1].stock) >= data.input then
            Player.Functions.RemoveMoney('cash', totalPrice)
            Player.Functions.AddItem(data.item, data.input)

            exports.oxmysql:executeSync('UPDATE disnaker_items SET stock = stock - ? WHERE category = ? AND item = ?', { data.input, data.key, data.item })

            local name = GetPlayerName(source)
            local steamhex = GetPlayerIdentifier(source)
            local communtiylogo = " "
            local logs = "https://discord.com/api/webhooks/1402216221545594961/ZPYmSt6zTG_335xmpQSIi_sWrunVR5fEfEycCnXDAK1ugErxCaMl-3M6NVrGifLzuReT"
            local disnakerbeli = {
                {
                    ["color"] = "1942002",
                    ["title"] = "Beli Disnaker",
                    ["description"] = "**Player:** " .. name ..  
                                    "\n**Steam Hex:** " .. steamhex .. 
                                    "\n\n**Membeli:** " .. data.item..
                                    "\n**Sebanyak:** " .. data.input..
                                    "\n**Total Harga:** TK$" .. totalPrice,
                    ["footer"] = {
                        ["text"] = "BAHTERA Logs • "..os.date("%a, %d %b %y at %H:%M%p"),
                        ["icon_url"] = communtiylogo,
                    },
                }
    
            }
            PerformHttpRequest(logs, function(err, text, headers) end, 'POST', json.encode({username = "BELI DISNAKER", embeds = disnakerbeli}), { ['Content-Type'] = 'application/json' })
            return true
        else
            return false
        end
    else
        TriggerClientEvent("QBCore:Notify", source, "Anda Tidak Memiliki Uang!")
        return false
    end
end)

