exports('GetOwnedHomes', function()
    local ownedHomes = {}
    for k, data in pairs(Homes) do
        if data.properties.owner == (GetIdentifier()) and data.properties.complex == 'Individual' then
            table.insert(ownedHomes, data)
        elseif data.properties.complex == 'Apartment' and Apartments[data.identifier]:OwnApartment() then
            table.insert(ownedHomes, data)
        elseif Homes[data.identifier]:isTenant() then
            table.insert(ownedHomes, data)
        end
    end
    for _, apt in pairs(Flats) do
        for _, data in pairs(apt.rooms) do
            if data.properties.owner == (GetIdentifier()) then
                local room = table.clone(data)
                room.entry = room.flat.coords
                table.insert(ownedHomes, room)
            end
        end
    end
    return ownedHomes
end)

exports('GetRealestateHomes', function(job)
    local list = {}
    for k, data in pairs(Homes) do
        if data.properties.realestate and data.properties.realestate == job and data.properties.complex == 'Individual' then
            table.insert(list, data)
        end
    end
    for _, apt in pairs(Flats) do
        for _, data in pairs(apt.rooms) do
            if data.properties.realestate and data.properties.realestate == job then
                local room = table.clone(data)
                room.entry = room.flat.coords
                table.insert(list, room)
            end
        end
    end
    return list
end)

exports('GetOwnedHomeKeys', function()
    local ownedHomes = {}
    for k, data in pairs(Homes) do
        if data.keys and data.keys:HasKey(GetIdentifier()) and data.properties.complex == 'Individual' then
            table.insert(ownedHomes, data)
        elseif data.properties.complex == 'Apartment' and Apartments[data.identifier]:OwnApartment() then
            table.insert(ownedHomes, data)
        elseif Homes[data.identifier]:isTenant() then
            table.insert(ownedHomes, data)
        end
    end
    for _, apt in pairs(Flats) do
        for _, data in pairs(apt.rooms) do
            if data.keys and data.keys:HasKey(GetIdentifier()) then
                local room = table.clone(data)
                room.entry = room.flat.coords
                table.insert(ownedHomes, room)
            end
        end
    end
    return ownedHomes
end)

exports('GetOwnedRentedHomes', function()
    local ownedHomes = {}
    for k, data in pairs(Homes) do
        if data.properties.owner == (GetIdentifier()) and data.properties.complex == 'Individual' then
            if data.properties.rent and data.properties.rent.isRented then
                table.insert(ownedHomes, data)
            end
        end
    end
    for _, apt in pairs(Flats) do
        for _, data in pairs(apt.rooms) do
            if data.properties.owner == (GetIdentifier()) then
                if data.properties.rent and data.properties.rent.isRented then
                    local room = table.clone(data)
                    room.entry = room.flat.coords
                    table.insert(ownedHomes, room)
                end
            end
        end
    end
    return ownedHomes
end)

exports('GetHomes', function()
    local list = {}
    for k, data in pairs(Homes) do
        if data.properties.complex ~= 'Flat' then
            table.insert(list, data)
        end
    end
    for _, apt in pairs(Flats) do
        for _, data in pairs(apt.rooms) do
            local room = table.clone(data)
            room.entry = room.flat.coords
            table.insert(list, room)
        end
    end
    return list
end)

exports('GetHome', function(homeId)
    return Homes[homeId] or false
end)

exports('LockHome', function(homeId)
    local home = Homes[homeId]
    if home and home.keys:HasKey(GetIdentifier()) then
        TriggerServerEvent('Housing:server:LockHome', homeId)
    end
end)

exports('isLocked', function(homeId, aptId)
    local id = homeId or CurrentHome.identifier
    local home = Homes[homeId]
    if home then
        if home.properties.complex == 'Apartment' then
            return Apartments[id]:isLocked(aptId)
        else
            return home.properties.locked
        end
    else
        return false
    end
end)

exports('GetKeyList', function(homeId)
    local home = Homes[homeId]
    return home and home.keys.list or {}
end)

exports('GetKeyHolders', function(homeId)
    local home = Homes[homeId]
    if home then
        local holders = {}
        for k, v in pairs(home.keys.holders) do
            holders[#holders + 1] = { identifier = k, name = v.name, key = v.key }
        end
        return holders
    else
        return {}
    end
end)

exports('GetStarterApartment', function()
    return StarterApartment
end)

exports('AddKeyHolder', function(homeId, target, keyName)
    local home = Homes[homeId]
    if home then
        if #exports[GetCurrentResourceName()]:GetKeyHolders(homeId) < home.configuration.keys then
            local result = lib.callback.await("Housing:server:GiveHomeKeyHolder", false, homeId, target, keyName)
            if result.success then
                home.keys:UpdateHolder(result.identifier, result.name, keyName)
                Notify(locale('housing'), locale('key_given_successfully', keyName, result.name), 'success', 5000)
            else
                Notify(locale('housing'), locale('key_give_error'), 'error', 3000)
            end
            return result.success
        else
            Notify(locale('housing'), locale('max_keys_exceeded'), 'error', 3000)
            return false
        end
    else
        return false
    end
end)

exports('RemoveKeyHolder', function(homeId, identifier)
    local home = Homes[homeId]
    if home then
        local result = lib.callback.await("Housing:server:RemoveKeyHolder", false, homeId, identifier)
        if result then
            home.keys:DeleteHolder(identifier)
            Notify(locale('housing'), locale('key_removed_successfully'), 'success', 3000)
        else
            Notify(locale('housing'), locale('key_removal_error'), 'error', 3000)
        end
        return result
    else
        return false
    end
end)

exports('HasKey', function(homeId, permission)
    local home = Homes[homeId]
    return home.keys:HasKey(GetIdentifier(), permission)
end)

exports('SetWaypoint', function(homeId)
    local home = Homes[homeId]
    ClearGpsPlayerWaypoint()
    local entry = home:GetEntryCoords()
    SetNewWaypoint(entry.x, entry.y)
end)

exports('GetPlayersInside', function(homeId)
    local home = Homes[homeId]
    if home then
        return home:GetPlayersInside()
    end
end)

exports('GetLastProperty', function()
    return lib.callback.await('Housing:server:GetLastProperty', false)
end)
