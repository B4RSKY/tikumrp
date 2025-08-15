local playerDistances = {}
local showIDPlayers = false

local function DrawText3D(x,y,z, text, r,g,b) 
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px,py,pz)-vector3(x,y,z))
 
    local scale = (1/dist)*2
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov
   
    if onScreen then
        if not useCustomScale then
            SetTextScale(0.0*scale, 0.55*scale)
        else 
            SetTextScale(0.0*scale, customScale)
        end
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(r, g, b, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

CreateThread(function()
    while true do
    	Wait(1000)
        for _, id in ipairs(GetActivePlayers()) do
            x1, y1, z1 = table.unpack(GetEntityCoords(cache,ped, true))
            x2, y2, z2 = table.unpack(GetEntityCoords(GetPlayerPed(id), true))
            distance = math.floor(#(vector3(x1,  y1,  z1)-vector3(x2,  y2,  z2)))
			playerDistances[id] = distance
        end        
    end
end)

local function showIDEnable()
	showIDPlayers = true
end

CreateThread(function()
    while true do
        Wait(0)
        if showIDPlayers then
            for _, id in ipairs(GetActivePlayers()) do
                if playerDistances[id] then
                    if (playerDistances[id] < 2) then
                        local x2, y2, z2 = table.unpack(GetEntityCoords(GetPlayerPed(id), true))
                        if IsEntityVisible(GetPlayerPed(id)) then
                            if NetworkIsPlayerTalking(id) then
                                DrawText3D(x2, y2, z2 + 1, GetPlayerServerId(id), 0, 191, 255)
                            else
                                DrawText3D(x2, y2, z2 + 1, GetPlayerServerId(id), 255, 255, 255)
                            end
                        end
                    end
                end
            end
        end
    end
end)

local function showIDDisable()
	showIDPlayers = false
end

CreateThread(function()
    RegisterCommand('+isshowIDPlayer', showIDEnable, false)
    RegisterCommand('-isshowIDPlayer', showIDDisable, false)
end)
