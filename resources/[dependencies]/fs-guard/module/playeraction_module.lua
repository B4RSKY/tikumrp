-- Path: template.lua (FutureSeekerTech) 
-----------------------------------------------------------------------------
-- Variable Define
local discordWebHook = 'https://discord.com/api/webhooks/1404437418978840628/3WPHD8byhjO-5ODwDK5hC__eMM32SBufa6KcF-ChYPIJaftnxPmIv2W6lQi2MJFcV8V1'

-----------------------------------------------------------------------------
--  Function Define

function GuardNotify(name, ip, steam, hwid, license, discord, eventName, banId)
	local msg = {["color"] = "10552316", ["type"] = "rich", ["title"] = "Unauthorized Event Triggered", ["description"] =  "**Name : **" ..name .. "\n **Reason : **" .."This player trigger unauthorized event".. "\n **Event : **||" ..eventName.. "||\n **IP : **||" ..ip.. "||\n **Steam : **||" .. steam .. "||\n **HWID: **||" ..hwid.. "||\n **Rockstar License : **||" .. license .. "||\n **Discord : **<@" .. discord .. ">".."||\n **Ban ID : **"..tostring(banId), ["footer"] = { ["text"] = " © barsky.gg | "..os.date("%c").."" }}
	if name ~= "Unknown" then
	  PerformHttpRequest(discordWebHook, function(err, text, headers) end, "POST", json.encode({username = "AC - Exploit", embeds = {msg}, avatar_url = "https://cdn.discordapp.com/attachments/1078837522882367508/1114897951177855059/fstech_logo.png"}), {["Content-Type"] = "application/json"})
	end
end exports("GuardNotify", GuardNotify)


-----------------------------------------------------------------------------
-- Register Event

RegisterNetEvent('fs-guard:server:dropPlayer', function(id, license, steam, hwid, discord, ip, reason, banid)
    -- Data dari parameter event bisa digunakan untuk custom message drop player
    -- Secure Drop Player Event only can be triggered from fs-guard resource
    local invoking = GetInvokingResource()
    if invoking == nil then return end
    if invoking == "fs-guard" then
        -- Drop Player
	    DropPlayer(id, 'You are banned!\nReason: '..reason..'\nBan ID: '..banid..'\nPlease contact the server owner for more information.')
    end
end)

-----------------------------------------------------------------------------
-- Threads




-----------------------------------------------------------------------------
-- Event Handler

-- Player Checker
local function OnPlayerConnecting(name, setKickReason, deferrals)
    local player = source
    data = GetBanStatus(player)
    deferrals.defer()
    -- mandatory wait!
    Wait(0)
    deferrals.update(string.format("Checking your ban status."))
    -- mandatory wait!
    Wait(0)
    if data and data.ban then
        reason = data.reason or "Exploiting"
        deferrals.done('\nYou are banned!\nReason: '..reason..'\nBan ID: '..data.banid..'\nPlease contact the server owner for more information.')
        CancelEvent()
    end
    Citizen.Wait(5000)
    deferrals.done()
end

AddEventHandler("playerConnecting", OnPlayerConnecting)


-----------------------------------------------------------------------------
-- End Of File (FutureSeekerTech) 