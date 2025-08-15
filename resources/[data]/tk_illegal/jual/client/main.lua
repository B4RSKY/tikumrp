local QBCore = exports['qb-core']:GetCoreObject()
local cfg = ClientConfig

local Zones = {}
local ZonePeds = {}
local LeashAlive = {}

local function randf(min,max) return min + (max - min) * math.random() end
local function choice(t) return t[math.random(1, #t)] end

local function randomPointInZone(center, radius)
    local r = randf(cfg.SpawnOffset.min, math.min(cfg.SpawnOffset.max, radius - 1.0))
    local theta = randf(0.0, math.pi * 2.0)
    return vec3(center.x + r * math.cos(theta), center.y + r * math.sin(theta), center.z)
end

local function ensureModel(model)
    lib.requestModel(model, 50000)
    return HasModelLoaded(model)
end

local function isGangBoleh()
    local pd = QBCore.Functions.GetPlayerData()
    local g = (pd and pd.gang and pd.gang.name) and string.lower(pd.gang.name) or ''
    for _, n in ipairs(cfg.AllowedGangs) do
        if g == string.lower(n) then return true end
    end
    return false
end

local function getZoneDef(zoneId)
    for _, z in ipairs(cfg.Zones) do if z.id == zoneId then return z end end
end

local function deletePedHandle(ped)
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        SetEntityAsMissionEntity(ped, true, true)
        DeleteEntity(ped)
    end
    LeashAlive[ped] = false
end

local function removePedObjFromPool(zoneId, pedObj)
    local list = ZonePeds[zoneId]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i].ped == pedObj.ped then
            deletePedHandle(pedObj.ped)
            table.remove(list, i)
            return
        end
    end
end

local function startWander(ped, zdef)
    if not DoesEntityExist(ped) then return end
    local w = (zdef.wander or { enabled = true, speed = 1.0, retask = {min=9000, max=15000}, leashMargin = 5.0 })
    local speed = w.speed or 1.0

    ClearPedTasks(ped)
    TaskWanderStandard(ped, 10.0, 10)
    SetPedPathPreferToAvoidWater(ped, true)
    SetPedPathAvoidFire(ped, true)
    SetPedPathCanUseLadders(ped, false)

    LeashAlive[ped] = true
    local function leashTick()
        if not LeashAlive[ped] or not DoesEntityExist(ped) then return end
        local dist = #(GetEntityCoords(ped) - zdef.coords)
        local margin = w.leashMargin or 5.0

        if dist > (zdef.radius + margin) then
            local dest = randomPointInZone(zdef.coords, zdef.radius - 2.0)
            ClearPedTasks(ped)
            TaskFollowNavMeshToCoord(ped, dest.x, dest.y, dest.z, speed, -1, 1.0, false, 0)
        elseif math.random() < 0.35 then
            ClearPedTasks(ped)
            TaskWanderStandard(ped, 10.0, 10)
        end

        local delay = math.floor(randf((w.retask and w.retask.min or 9000), (w.retask and w.retask.max or 15000)))
        SetTimeout(delay, leashTick)
    end
    SetTimeout(math.floor(randf(3000, 6000)), leashTick)
end

local function setTargetKePed(pedObj, zoneId)
    local ped = pedObj.ped
    local options = {{
        icon = 'fa-solid fa-hand-holding-dollar',
        label = 'Jual',
        distance = 2.0,
        onSelect = function()
            if not isGangBoleh() then return end

            local zdef = getZoneDef(zoneId); if not zdef then return end

            local sellItem = zdef.sellItem
            if not sellItem then
                if zdef.allowedItems and #zdef.allowedItems > 0 then
                    sellItem = zdef.allowedItems[1]
                else
                    for name,_ in pairs(cfg.Items) do sellItem = name break end
                end
            end
            if not sellItem or not cfg.Items[sellItem] then
                lib.notify({ title = 'Gagal', description = 'Di area ini tidak menerima barang anda', type='error', position = 'top-right', duration = 3500 })
                return
            end

            if DoesEntityExist(ped) then FreezeEntityPosition(ped, true) end
            local me = PlayerPedId()
            lib.requestAnimDict('mp_common', 2000)
            TaskPlayAnim(me, 'mp_common', 'givetake1_a', 8.0, -8.0, math.floor(cfg.GiveAnimTime*1000), 49, 0.0, false, false, false)
            if DoesEntityExist(ped) then
                TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 8.0, -8.0, math.floor(cfg.GiveAnimTime*1000), 49, 0.0, false, false, false)
            end
            Wait(math.floor(cfg.GiveAnimTime * 1000))
            ClearPedTasks(me)

            local ok, result = lib.callback.await('tk-illegal:jual', false, zoneId, sellItem, cfg.RequiredAmount)
            if ok then
                lib.notify({
                    title = 'Transaksi sukses', description = ('Terjual %dx %s, dibayar TK$%d'):format(result.amount, result.itemLabel, result.paid), type = 'success', position = 'top-right', duration = 3500})

                local zcap = (getZoneDef(zoneId).salesCap) or cfg.PedSalesCap or 1
                pedObj.sales = (pedObj.sales or 0) + 1

                if pedObj.sales >= zcap then
                    removePedObjFromPool(zoneId, pedObj)
                    if Zones[zoneId] and Zones[zoneId].isInside then
                        local list = ZonePeds[zoneId] or {}
                        local limit = (getZoneDef(zoneId).maxPeds or cfg.MaxPedsPerZone)
                        while #list < limit do
                            local new = CreateZonePed(getZoneDef(zoneId))
                            if not new then break end
                            list[#list+1] = new
                            if cfg.SpawnBurstDelay and cfg.SpawnBurstDelay > 0 then Wait(cfg.SpawnBurstDelay) else Wait(0) end
                        end
                        ZonePeds[zoneId] = list
                    end
                else
                    if DoesEntityExist(ped) then FreezeEntityPosition(ped, false) end
                end
            else
                if DoesEntityExist(ped) then FreezeEntityPosition(ped, false) end
                lib.notify({title = 'Gagal', description = result or ('Minimal %d'):format(cfg.RequiredAmount), type = 'error', position = 'top-right', duration = 3500})
            end
        end,
        canInteract = function(ent, distance, _)
            if distance > 2.2 then return false end
            return isGangBoleh()
        end
    }}
    exports.ox_target:addLocalEntity(ped, options)
end

function CreateZonePed(zdef)
    if not zdef or not zdef.coords or not zdef.npcModels or #zdef.npcModels == 0 then return nil end
    local pos = randomPointInZone(zdef.coords, zdef.radius)
    local model = choice(zdef.npcModels)
    if not ensureModel(model) then return nil end

    local ped = CreatePed(4, model, pos.x, pos.y, pos.z, math.random(0, 359) + .0, false, false)
    if ped == 0 then return nil end

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetEntityAsMissionEntity(ped, true, true)

    if not zdef.wander or zdef.wander.enabled ~= false then
        startWander(ped, zdef)
    elseif zdef.scenario then
        TaskStartScenarioInPlace(ped, zdef.scenario, 0, true)
    end

    local obj = { ped = ped, sales = 0 }
    setTargetKePed(obj, zdef.id)
    return obj
end

local function fillZonePeds(zdef)
    local zoneId = zdef.id
    local list = ZonePeds[zoneId] or {}
    local limit = zdef.maxPeds or cfg.MaxPedsPerZone
    local need = limit - #list
    for _ = 1, need do
        local obj = CreateZonePed(zdef)
        if obj then list[#list+1] = obj end
        if cfg.SpawnBurstDelay and cfg.SpawnBurstDelay > 0 then Wait(cfg.SpawnBurstDelay) else Wait(0) end
    end
    ZonePeds[zoneId] = list
end

local function clearZonePeds(zoneId)
    local list = ZonePeds[zoneId]
    if not list then return end
    for i = #list, 1, -1 do
        deletePedHandle(list[i].ped)
        table.remove(list, i)
    end
    ZonePeds[zoneId] = nil
end

local function setupZones()
    for _, z in ipairs(cfg.Zones) do
        local zone = lib.zones.sphere({
            coords = z.coords,
            radius = z.radius,
            debug = false,
            inside = function() end,
            onEnter = function()
                Zones[z.id].isInside = true
                if not isGangBoleh() then return end
                fillZonePeds(z)
            end,
            onExit = function()
                Zones[z.id].isInside = false
                clearZonePeds(z.id)
            end
        })
        Zones[z.id] = { zone = zone, isInside = false }
    end
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id, data in pairs(Zones) do if data.zone then data.zone:remove() end end
    for zoneId, _ in pairs(ZonePeds) do clearZonePeds(zoneId) end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    for zoneId, _ in pairs(ZonePeds) do clearZonePeds(zoneId) end
end)

RegisterNetEvent('tk-illegal:jual:call', function(payload)
    if not cfg.Dispatch or not cfg.Dispatch.enabled then return end
    local ok = pcall(function()
        exports['ps-dispatch']:DrugSale()
    end)
end)

CreateThread(function()
    math.randomseed(GetGameTimer())
    setupZones()
end)
