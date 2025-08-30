local QBCore = exports['qb-core']:GetCoreObject()

local Webhooks = {
    ['invgive'] = 'https://discord.com/api/webhooks/1408337007977173114/HO4cg1UKqhZV7BbGBEhNbDpC3AVSw_NiDVycw61NZFkNcT5SmlSnslWrz-DsOkiYohDW',
    ['invdrop'] = 'https://discord.com/api/webhooks/1408337088738230325/RDbROc-FMB25kNRQJJSvtdQdzIYyP3wdQsBXSdhJ4RVQKQbwzBQu32I7lzkmbDU5oB0O',
    ['invswap'] = 'https://discord.com/api/webhooks/1408337049844449290/z1waLA8wMWSpsMdIn8rrOTnK5Jo0jJl8CGSdwQwTByNHxGvO3--N5jhfY8S-ZLZXfE84',
    ['drug_sale'] = 'https://discord.com/api/webhooks/1405470600465481751/mCIw9rXAcw_ekjTzok9cMHi8BNktRYWsohTymMrER-Eyg9fk5x9v4yDi4CcCvh7Zns7B',
    ['default'] = '',
    ['exploit'] = 'https://discord.com/api/webhooks/1408377031988609144/w75t4Eva41YeePRegErVksF6Mcj4Au-4mAjPQUI4QX3oBVfnM3xvAyaMPdAG8K263eS7',
    ['jobmanagement'] = 'https://discord.com/api/webhooks/1411349556641398909/oLDcSpVEPet-kujZtQvGgVtQiMU7i_RHQpIfTGejirg1sGs50SZCiyESTnLfjDTUAuEU',
    ['testwebhook'] = '',
    ['playermoney'] = '',
    ['playerinventory'] = '',
    ['robbing'] = '',
    ['cuffing'] = '',
    ['drop'] = '',
    ['trunk'] = '',
    ['stash'] = '',
    ['glovebox'] = '',
    ['bankdepo'] = 'https://discord.com/api/webhooks/1408339132241154089/6SLgVrNcZ4J3uKBacem4HnYQJBDTY_DPnloA5ZIwf5MciUqgjGhkI2191ys1a8vSXY5_',
    ['bankwd'] = 'https://discord.com/api/webhooks/1408343833254690836/mNfTO6VT8MwdQ6kPKMSJxO_RyN4as_JKGwVNdKGERgxdzmp9vsxV16TGgzJUdV29HAb3',
    ['banktf'] = 'https://discord.com/api/webhooks/1408344503198421032/mcfbFWH5ZUJR163wMGouYJHQPBxzldS19HvvoImLnyMWoyiGKxHNQJFXTRRzexL1eX6S',
    ['vehicleshop'] = 'https://discord.com/api/webhooks/1410106285096964137/26HtzO8jyPxpMuOvKz0FG7_M3sCpMd46Aj0NOhhMVKYWDp45kFNiDoZC-T0f0BGXc4W1',
    ['vehicleupgrades'] = '',
    ['shops'] = '',
    ['dealers'] = '',
    ['storerobbery'] = '',
    ['bankrobbery'] = '',
    ['powerplants'] = '',
    ['death'] = '',
    ['join'] = 'https://discord.com/api/webhooks/1405136545618591826/XMzgjB2btNmzLx2Y1vGmC1W8s1qfr9uif-H92FpBTi1A1wIJ_ok559Eh4bDsCpKsZHjl',
    ['keluar'] = 'https://discord.com/api/webhooks/1405136928826982481/nMpM2ZpcHR32KUZJa7Edw3peRjw01ReLZ9sM2b8qwugOurgWv65DvS626lIyAwsTne2P',
    ['ooc'] = '',
    ['report'] = '',
    ['me'] = '',
    ['pmelding'] = '',
    ['112'] = '',
    ['bans'] = '',
    ['anticheat'] = '',
    ['weather'] = '',
    ['moneysafes'] = '',
    ['bennys'] = '',
    ['bossmenu'] = '',
    ['robbery'] = '',
    ['casino'] = '',
    ['traphouse'] = '',
    ['911'] = '',
    ['palert'] = '',
    ['house'] = '',
    ['qbjobs'] = '',
}

local colors = { -- https://www.spycolor.com/
    ['default'] = 14423100,
    ['blue'] = 255,
    ['red'] = 16711680,
    ['green'] = 65280,
    ['white'] = 16777215,
    ['black'] = 0,
    ['orange'] = 16744192,
    ['yellow'] = 16776960,
    ['pink'] = 16761035,
    ['lightgreen'] = 65309,
    ['ungu'] = 5515437,
}

local logQueue = {}

RegisterNetEvent('qb-log:server:CreateLog', function(name, title, color, message, tagEveryone, imageUrl)
    local tag = tagEveryone or false

    if Config.Logging == 'discord' then
        if not Webhooks[name] then
            print('Tried to call a log that isn\'t configured with the name of ' .. name)
            return
        end
        local webHook = Webhooks[name] ~= '' and Webhooks[name] or Webhooks['default']
        local embedData = {
            {
                ['title'] = title,
                ['color'] = colors[color] or colors['ungu'],
                ['footer'] = {
                    ["text"] = "TIKUMRP Logs • "..os.date("%a, %d %b %y at %H:%M%p"),
                },
                ['description'] = message,
                ['author'] = {
                    ['name'] = 'TIKUMRP Logs',
                    ['icon_url'] = 'https://files.fivemerr.com/images/a437452f-5f0d-4550-aa83-2ac7e4aaa394.png',
                },
                ['image'] = imageUrl and imageUrl ~= '' and { ['url'] = imageUrl } or nil,
            }
        }

        if not logQueue[name] then logQueue[name] = {} end
        logQueue[name][#logQueue[name] + 1] = { webhook = webHook, data = embedData }

        if #logQueue[name] >= 10 then
            local postData = { username = 'TIKUMRP System', embeds = {} }

            if tag then
                postData.content = '@everyone'
            end

            for i = 1, #logQueue[name] do postData.embeds[#postData.embeds + 1] = logQueue[name][i].data[1] end
            PerformHttpRequest(logQueue[name][1].webhook, function() end, 'POST', json.encode(postData), { ['Content-Type'] = 'application/json' })
            logQueue[name] = {}
        end
    elseif Config.Logging == 'fivemanage' then
        local FiveManageAPIKey = GetConvar('FIVEMANAGE_LOGS_API_KEY', 'false')
        if FiveManageAPIKey == 'false' then
            print('You need to set the FiveManage API key in your server.cfg')
            return
        end
        local extraData = {
            level = tagEveryone and 'warn' or 'info', -- info, warn, error or debug
            message = title,                          -- any string
            metadata = {                              -- a table or object with any properties you want
                description = message,
                playerId = source,
                playerLicense = GetPlayerIdentifierByType(source, 'license'),
                playerDiscord = GetPlayerIdentifierByType(source, 'discord')
            },
            resource = GetInvokingResource(),
        }
        PerformHttpRequest('https://api.fivemanage.com/api/logs', function(statusCode, response, headers)
            -- Uncomment the following line to enable debugging
            -- print(statusCode, response, json.encode(headers))
        end, 'POST', json.encode(extraData), {
            ['Authorization'] = FiveManageAPIKey,
            ['Content-Type'] = 'application/json',
        })
    end
end)

CreateThread(function()
    local timer = 0
    while true do
        Wait(1000)
        timer = timer + 1
        if timer >= 60 then -- If 60 seconds have passed, post the logs
            timer = 0
            for name, queue in pairs(logQueue) do
                if #queue > 0 then
                    local postData = { username = 'TIKUMRP System', embeds = {} }
                    for i = 1, #queue do
                        postData.embeds[#postData.embeds + 1] = queue[i].data[1]
                    end
                    PerformHttpRequest(queue[1].webhook, function() end, 'POST', json.encode(postData), { ['Content-Type'] = 'application/json' })
                    logQueue[name] = {}
                end
            end
        end
    end
end)

QBCore.Commands.Add('testwebhook', 'Test Your Discord Webhook For Logs (God Only)', {}, false, function()
    TriggerEvent('qb-log:server:CreateLog', 'testwebhook', 'Test Webhook', 'default', 'Webhook setup successfully')
end, 'god')
