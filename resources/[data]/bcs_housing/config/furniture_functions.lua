Config = Config or {}

Config.FurnitureFunctions = {
    ['computer'] = function(entity, homeId, isArea, furniture)
        print(entity, homeId, isArea, json.encode(furniture, { indent = true }))
    end,
    ['storage'] = function(entity, homeId, isArea, furniture)
        local DEFAULT_ZONE_SIZE = vec3(1.5, 1.5, 2.5)
        local home = Homes[homeId]
        if home then
            -- if home:GetStorage(furniture.identifier) then
            --     return
            -- end

            local slots = FurnitureModelList[furniture.model] and
                FurnitureModelList[furniture.model].slots or Config.FurnitureStorage.slots
            local weight = FurnitureModelList[furniture.model] and
                FurnitureModelList[furniture.model].weight or Config.FurnitureStorage.weight
            home:CreateStorage(furniture.identifier, furniture.coords, weight, slots, isArea)
            if Config.target then
                RemoveTargetEntity(entity, "Open Storage")
                AddTargetEntity("storage:" .. homeId .. ":" .. furniture.identifier, entity, {
                    options = {
                        {
                            identifier = "storage:" .. homeId .. ":" .. furniture.identifier,
                            owner = home.properties.owner,
                            home = homeId,
                            event = "Housing:Storage",
                            icon = "fas fa-box-open",
                            label = "Open Storage",
                            slots = slots,
                            weight = weight
                        },
                    },
                    distance = 3.5,
                })
            else
                if home.zones.storages[furniture.identifier] then
                    home.zones.storages[furniture.identifier]:remove()
                end
                local storage = {
                    identifier = "storage:" .. homeId .. ":" .. furniture.identifier,
                    owner = home.properties.owner,
                    home = homeId,
                    slots = furniture.slot or Config.DefaultSlots,
                }
                local min, max = GetModelDimensions(GetEntityModel(entity))
                local size = max + DEFAULT_ZONE_SIZE

                home.zones.storages[furniture.identifier] = lib.zones.box({
                    name = furniture.identifier,
                    coords = GetEntityCoords(entity),
                    debug = Config.debug,
                    size = size,
                    rotation = GetEntityHeading(entity),
                    onEnter = function()
                        inZone = true
                        StoragePrompt(storage)
                    end,
                    onExit = ExitZone
                })
            end
        end
    end,
    ['door'] = function(entity, homeId, isArea, furniture)
        debugPrint(entity, homeId, isArea, json.encode(furniture, { indent = true }))
        FreezeEntityPosition(entity, false)
    end,
    ['light_switch'] = function(entity, homeId, isArea, furniture)
        local home = Homes[homeId]
        if home then
            local data = FindEntitySetData(home:GetEntryCoords())
            if Config.target and data and next(data) then
                RemoveTargetEntity(entity, "Turn on/off light")
                AddTargetEntity("lightswitch:" .. homeId .. ":" .. furniture.light, entity, {
                    options = {
                        {
                            icon = "fas fa-box-open",
                            label = "Turn on/off light",
                            action = function()
                                local interiorId = GetInteriorFromEntity(entity)
                                local active = IsInteriorEntitySetActive(interiorId, furniture.light)
                                exports.bob74_ipl:SetIplPropState(interiorId, furniture.light, not active, true)
                            end
                        },
                    },
                    distance = 3.5,
                })
            end
        end
    end,
    ['bell'] = function(entity, homeId, isArea, furniture)
        if Config.target then
            RemoveTargetEntity(entity, "Bell")
            AddTargetEntity("bell:" .. homeId, entity, {
                options = {
                    {
                        icon = "fas fa-bell",
                        label = "Door Bell",
                        action = function()
                            RingBell(entity, homeId)
                        end
                    },
                },
                distance = 2.0,
            })
        end
    end,
}
