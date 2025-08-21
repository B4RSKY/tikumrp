if Config.Logs ~= 'discord' then return end

local discordWebhook = 'https://discord.com/api/webhooks/1407992936284688416/Z0AFnTy5VnrHbu0LHUs745imWUADJ5ZHyAy5HDBn1UQbpP42I1WZP0g5-IyMF4qIc0Ln'

local discord = {
    send = function(title, description, color)
        local embed = {
            {
                ["title"] = title,
                ["description"] = description,
                ["color"] = color,
                ["footer"] = {
                    ["text"] = 'TeamsGG Development',
                },
            }
        }
        PerformHttpRequest(discordWebhook, function(err, text, headers) end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
    end
}

Logs = {
    TransferVehicle = function(buyer, seller, vehModel, vehDescription, vehPrice, plate)
        discord.send('VEHICLE SALE',
            ('**Vehicle model:** %s \n**Vehicle description:** %s \n**Plate:** %s \n**Buyer identifier:** %s \n**Seller identifier:** %s \n**Price:** $%s'):format(vehModel, vehDescription, plate, buyer, seller, vehPrice), 65280)
    end,
}
