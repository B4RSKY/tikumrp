local RawConfig = require 'starterpack.shared.config'
local Cfg = RawConfig.Starterpack or RawConfig.Staterpack or RawConfig
local QBCore = exports['qb-core']:GetCoreObject()

local lastUse = {}
local lastUseRegister = {}
local AllowedModels = {}

CreateThread(function()
    local q = ([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `citizenid` VARCHAR(50) NOT NULL,
            `claimed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format('tk_starterpack')
    MySQL.query(q)
end)

local function getPlayer(src)
    return QBCore.Functions.GetPlayer(src)
end

local function getCitizenId(src)
    local p = getPlayer(src)
    return p and p.PlayerData.citizenid or nil
end

local function hitRateLimit(src)
    local now = os.clock()
    local last = lastUse[src] or 0.0
    if (now - last) < (Cfg.RateLimitSeconds or 5) then return true end
    lastUse[src] = now
    return false
end

local function buildAllowedModels()
    AllowedModels = {}
    local v = Cfg.Vehicle
    if v and v.enabled ~= false then
        if type(v.fixedModel) == 'string' and v.fixedModel ~= '' then
            AllowedModels[v.fixedModel] = true
        end
        if type(v.randomPool) == 'table' then
            for _, m in ipairs(v.randomPool) do
                if type(m) == 'string' and m ~= '' then
                    AllowedModels[m] = true
                end
            end
        end
    end
end
CreateThread(buildAllowedModels)

local function hitRateLimitRegister(src)
    local now = os.clock()
    local last = lastUseRegister[src] or 0.0
    if (now - last) < 2.0 then
        return true
    end
    lastUseRegister[src] = now
    return false
end

local function hasStarterVehicle(citizenid)
    local models = {}
    for model, _ in pairs(AllowedModels) do
        models[#models+1] = model
    end
    if #models == 0 then return false end

    local placeholders = ('?,' ):rep(#models):sub(1, -2)
    local q = (('SELECT 1 FROM `%s` WHERE citizenid = ? AND vehicle IN (%s) LIMIT 1')):format('player_vehicles', placeholders)

    local params = { citizenid }
    for i = 1, #models do params[#params+1] = models[i] end

    local row = MySQL.single.await(q, params)
    return row ~= nil
end

local function pickVehicleModel()
    if not Cfg.Vehicle.enabled then return nil end
    if Cfg.Vehicle.mode == 'random' and type(Cfg.Vehicle.randomPool) == 'table' and #Cfg.Vehicle.randomPool > 0 then
        return Cfg.Vehicle.randomPool[math.random(1, #Cfg.Vehicle.randomPool)]
    end
    return Cfg.Vehicle.fixedModel or 'asea'
end

local function alreadyClaimed(citizenid)
    local row = MySQL.single.await(
        ('SELECT citizenid FROM `%s` WHERE citizenid = ? LIMIT 1'):format('tk_starterpack'),
        { citizenid }
    )
    return row ~= nil
end

local function markClaimed(citizenid)
    return MySQL.prepare.await(
        ('INSERT INTO `%s` (citizenid) VALUES (?)'):format('tk_starterpack'),
        { citizenid }
    )
end

-- local function giveItems(src)

-- end
lib.callback.register('tk-stater:server:claim', function(source)
    local src = source
    if hitRateLimit(src) then
        return { ok = false, msg = 'Terlalu cepat. Coba lagi.' }
    end

    local citizenid = getCitizenId(src)
    if not citizenid then
        return { ok = false, msg = 'Player tidak valid.' }
    end

    if alreadyClaimed(citizenid) then
        return { ok = false, msg = 'Starter pack sudah pernah di-claim.' }
    end

    for _, it in ipairs(Cfg.Items) do
        if it.name and it.count and it.count > 0 then
            exports.ox_inventory:AddItem(src, it.name, it.count)
        end
    end

    local spawnData = nil
    if Cfg.Vehicle.enabled then
        local model = pickVehicleModel()
        spawnData = {
            model = model,
            garage = Cfg.Vehicle.garage,
            spawn = Cfg.Vehicle.spawnVehicle == true,
            warp  = Cfg.Vehicle.warpIntoVehicle == true,
            giveKeysEvent = Cfg.Vehicle.giveKeysEvent,
            state = Cfg.Vehicle.stateOnRegister or 1,
        }
    end

    markClaimed(citizenid)

    return { ok = true, msg = 'Starter pack berhasil di-claim!', vehicle = spawnData }
end)

RegisterNetEvent('tk-stater:server:register', function(model, plate, garage, state)
    local src = source
    if hitRateLimitRegister(src) then return end

    if type(model) ~= 'string' or model == '' then return end
    if type(plate) ~= 'string' or plate == '' then return end

    local Player = getPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    if not AllowedModels[model] then
        print(('[tk_starterpack] Blocked registerVehicle: disallowed model "%s" for %s'):format(model, citizenid))
        return
    end

    if not alreadyClaimed(citizenid) then
        TriggerClientEvent('QBCore:Notify', src, 'Anda belum claim starter pack.', 'error')
        print(('[tk_starterpack] Blocked registerVehicle: not claimed yet %s'):format(citizenid))
        return
    end

    if hasStarterVehicle(citizenid) then
        TriggerClientEvent('QBCore:Notify', src, 'Starter vehicle sudah terdaftar.', 'error')
        print(('[tk_starterpack] Blocked registerVehicle: already has starter vehicle %s'):format(citizenid))
        return
    end

    local license = Player.PlayerData.license or ''
    local hash = joaat(model)
    local mods = '{}'
    local q = ([[
        INSERT INTO `%s` (license, citizenid, vehicle, hash, mods, plate, state, garage)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]]):format('player_vehicles')

    MySQL.prepare(q, {
        license, citizenid, model, hash, mods, plate,
        state or (Cfg.Vehicle.stateOnRegister or 1),
        garage or Cfg.Vehicle.garage
    })
end)
