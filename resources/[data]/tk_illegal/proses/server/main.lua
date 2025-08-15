local Config = require 'proses.shared.config'
local QBCore = exports['qb-core']:GetCoreObject()

local Active = {}

local function getProcessorById(id)
    for _, p in ipairs(Config.Proses or {}) do
        if p.id == id then return p end
    end
end

local function hasAllowedJob(src, jobs)
    if not jobs or #jobs == 0 then return true end
    local x = QBCore.Functions.GetPlayer(src)
    if not x then return false end
    local job = x.PlayerData.job and x.PlayerData.job.name
    if not job then return false end
    for _, j in ipairs(jobs) do
        if j == job then return true end
    end
    return false
end

local function hasAllowedGang(src, gangs)
    if not gangs or #gangs == 0 then return true end
    local x = QBCore.Functions.GetPlayer(src)
    if not x then return false end
    local gang = x.PlayerData.gang and x.PlayerData.gang.name
    if not gang then return false end
    for _, g in ipairs(gangs) do
        if g == gang then return true end
    end
    return false
end

local function nearProcessor(src, p, extra)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local pc = GetEntityCoords(ped)
    local maxr = (p.radius or 2.0) + (extra or 0.0)
    return #(pc - p.coords) <= maxr
end

lib.callback.register('tk-illegal:proses:mulai', function(src, processorId, recipeIndex)
    if Active[src] then
        return { ok = false, msg = 'Kamu sedang memproses item lain.' }
    end

    local p = getProcessorById(processorId)
    if not p then
        return { ok = false, msg = 'Lokasi proses tidak ditemukan.' }
    end

    local resep = p.resep or {}
    local r = resep[recipeIndex]
    if not r then
        return { ok = false, msg = 'Barang yang dibutuhkan tidak valid.' }
    end

    if not hasAllowedJob(src, p.isJobs) then
        return { ok = false, msg = 'Tidak ada akses.' }
    end
    if not hasAllowedGang(src, p.isGeng) then
        return { ok = false, msg = 'Tidak ada akses.' }
    end

    if not nearProcessor(src, p, 0.8) then
        return { ok = false}
    end

    Active[src] = {
        p = p,
        r = r,
        start = GetGameTimer(),
        duration = p.duration or 5000
    }

    return { ok = true, duration = p.duration or 5000 }
end)

RegisterNetEvent('tk-illegal:proses:cancel', function()
    local src = source
    Active[src] = nil
end)

RegisterNetEvent('tk-illegal:proses:selesai', function()
    local src = source
    local a = Active[src]
    if not a then
        TriggerClientEvent('tk-illegal:proses:don', src, false, 'Tidak ada proses aktif.')
        return
    end

    local p, r = a.p, a.r
    Active[src] = nil

    local now = GetGameTimer()
    if now - a.start < (a.duration - 50) then
        TriggerClientEvent('tk-illegal:proses:don', src, false, 'Proses terlalu cepat.')
        return
    end

    if not nearProcessor(src, p, Config.FinishTolerance or 2.5) then
        TriggerClientEvent('tk-illegal:proses:don', src, false, 'Kamu menjauh dari lokasi.')
        return
    end

    local need = r.inCount or 1
    local removed = exports.ox_inventory:RemoveItem(src, r.input, need)
    if not removed then
        TriggerClientEvent('tk-illegal:proses:don', src, false,
        ('Butuh %dx %s.'):format(need, r.input))
        return
    end

    local added = exports.ox_inventory:AddItem(src, r.output, r.outCount or 1)
    if not added then
        exports.ox_inventory:AddItem(src, r.input, need)
        TriggerClientEvent('tk-illegal:proses:don', src, false, 'Tas penuh. Proses dibatalkan.')
        return
    end

    TriggerClientEvent('tk-illegal:proses:don', src, true,
        ('Selesai: %s → %s.'):format(r.input, r.output))
end)

AddEventHandler('playerDropped', function()
  Active[source] = nil
end)
