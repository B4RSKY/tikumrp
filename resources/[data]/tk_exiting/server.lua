local function getIdentifier(src)
    local ids = GetPlayerIdentifiers(src)
    if not ids or #ids == 0 then return ('src:%s'):format(src) end
    for _, id in ipairs(ids) do if id:find('steam:') then return id end end
    for _, id in ipairs(ids) do if id:find('discord:') then return id end end
    return ids[1]
end

AddEventHandler('playerDropped', function(reason)
    local src = source
    if not src then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local crds       = GetEntityCoords(ped)
    local identifier = getIdentifier(src)
    local name       = GetPlayerName(src) or ('ID %s'):format(src)
    local timeText   = os.date('%H:%M')

    for _, pidStr in ipairs(GetPlayers()) do
        local pid = tonumber(pidStr)
        if pid and pid ~= src then
            local pp = GetPlayerPed(pid)
            if pp ~= 0 then
                local dist = #(crds - GetEntityCoords(pp))
                if dist <= 50.0 then
                    TriggerClientEvent('tk_exiting:cl:spawnLabel', pid, {
                        id = src,
                        coords = crds,
                        identifier = identifier,
                        reason = tostring(reason or 'Unknown'),
                        duration = 25000,
                        maxDrawDist = 50.0,
                        timeText = timeText,
                        title = name,
                        scale = 2.5,
                        fontScale = 1.2,
                    })
                end
            end
        end
    end
end)