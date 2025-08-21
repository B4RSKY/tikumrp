currentBank = nil

--- Zones

for bank, value in pairs(Config.Banks) do
    if type(value.coords) == 'table' then
        lib.zones.poly({
            points = value.coords,
            thickness = value.size,
            debug = false,
            onEnter = function(self)
                currentBank = bank

                if not Config.Banks[bank].policeClose and Config.Banks[bank].hacked then
                    local object = GetClosestObjectOfType(Config.Banks[bank].vaultDoor.coords.x, Config.Banks[bank].vaultDoor.coords.y, Config.Banks[bank].vaultDoor.coords.z, 5.0, Config.Banks[bank].vaultDoor.object, false, false, false)
                    
                    if object ~= 0 then
                        SetEntityHeading(object, Config.Banks[bank].vaultDoor.open)
                        FreezeEntityPosition(object, true)
                    end
                else
                    local object = GetClosestObjectOfType(Config.Banks[bank].vaultDoor.coords.x, Config.Banks[bank].vaultDoor.coords.y, Config.Banks[bank].vaultDoor.coords.z, 5.0, Config.Banks[bank].vaultDoor.object, false, false, false)
                    
                    if object ~= 0 then
                        SetEntityHeading(object, Config.Banks[bank].vaultDoor.closed)
                        FreezeEntityPosition(object, true)
                    end
                end
            end,
            onExit = function(self)
                currentBank = nil
            end
        })
    else
        lib.zones.sphere({
            coords = value.coords,
            radius = value.size,
            debug = false,
            onEnter = function(self)
                currentBank = bank

                if not Config.Banks[bank].policeClose and Config.Banks[bank].hacked then
                    local object = GetClosestObjectOfType(Config.Banks[bank].vaultDoor.coords.x, Config.Banks[bank].vaultDoor.coords.y, Config.Banks[bank].vaultDoor.coords.z, 5.0, Config.Banks[bank].vaultDoor.object, false, false, false)
                    
                    if object ~= 0 then
                        SetEntityHeading(object, Config.Banks[bank].vaultDoor.open)
                        FreezeEntityPosition(object, true)
                    end
                else
                    local object = GetClosestObjectOfType(Config.Banks[bank].vaultDoor.coords.x, Config.Banks[bank].vaultDoor.coords.y, Config.Banks[bank].vaultDoor.coords.z, 5.0, Config.Banks[bank].vaultDoor.object, false, false, false)
                    
                    if object ~= 0 then
                        SetEntityHeading(object, Config.Banks[bank].vaultDoor.closed)
                        FreezeEntityPosition(object, true)
                    end
                end
            end,
            onExit = function(self)
                currentBank = nil
            end
        })
    end
end