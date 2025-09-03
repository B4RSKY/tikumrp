local QBCore = exports['qb-core']:GetCoreObject()

local ActiveBoxes = {}
local OwnerSpeakerMap = {}
local ModelToItem = {}
local PendingWipes = {}
for itemName, model in pairs(ServerCfg.Items or {}) do
    ModelToItem[model] = itemName
end

local function isNear(a, b, r) return #(a - b) <= r end
local function getCoords(src) local ped = GetPlayerPed(src); if ped ~= 0 then return GetEntityCoords(ped) end end
local function broadcast(ev, ...) TriggerClientEvent(ev, -1, ...) end
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end

local function parseIdsCSV(s)
    local out = {}
    if not s or s == '' then return out end
    for token in string.gmatch(s, '([^,%s]+)') do
        local n = tonumber(token)
        if n and n >= 1 and n <= 999 then out[#out + 1] = n end
    end
    return out
end

local T_BOX = ServerCfg.DB.TableBoxes
local T_SONG = ServerCfg.DB.TableSongs

local function dbCreateBox(ownerCid, coords, link, volume, distance, playing, model)
    local sql = ("INSERT INTO `%s` (owner_cid, x, y, z, link, volume, distance, playing, model) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"):format(T_BOX)
    local id = MySQL.insert.await(sql, {
        ownerCid, coords.x, coords.y, coords.z,
        link or nil,
        volume or 0.5,
        distance or 25,
        playing and 1 or 0,
        model or 'prop_boombox_01'
    })
    return id
end

local function dbUpdateBox(id, fields)
    if not id or not fields then return end
    local sets, params = {}, {}
    for k, v in pairs(fields) do sets[#sets + 1] = ("%s = ?"):format(k); params[#params + 1] = v end
    params[#params + 1] = id
    local q = ("UPDATE `%s` SET %s WHERE id = ?"):format(T_BOX, table.concat(sets, ", "))
    MySQL.update(q, params)
end

local function dbDeleteBox(id)
    if id then MySQL.update(("DELETE FROM `%s` WHERE id = ?"):format(T_BOX), { id }) end
end

local function dbListBoxesByCid(cid)
    local rows = MySQL.query.await(([[SELECT id, owner_cid, x, y, z, link, volume, distance, playing, model
                                        FROM `%s` WHERE owner_cid = ?]]):format(T_BOX), { cid }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = {
            id = r.id,
            ownerCid = r.owner_cid,
            coords = { x = r.x, y = r.y, z = r.z },
            link = r.link,
            volume = r.volume or 0.5,
            distance = r.distance or 25,
            playing = r.playing == 1,
            model = r.model or 'prop_boombox_01',
        }
    end
    return out
end

local function dbInsertSong(cid, name, url)
    return MySQL.insert.await(([[INSERT INTO `%s` (owner_cid, name, url) VALUES (?, ?, ?)]]):format(T_SONG), { cid, name, url })
end
local function dbDeleteSong(cid, id)
    return MySQL.update(([[DELETE FROM `%s` WHERE id = ? AND owner_cid = ?]]):format(T_SONG), { id, cid })
end
local function dbListSongs(cid)
    return MySQL.query.await(([[SELECT id, name, url, created_at FROM `%s` WHERE owner_cid = ? ORDER BY id DESC LIMIT 100]]):format(T_SONG), { cid }) or {}
end

local function mapBind(cid, speakerId, netId)
    OwnerSpeakerMap[cid] = OwnerSpeakerMap[cid] or {}
    OwnerSpeakerMap[cid][speakerId] = netId
end
local function mapUnbind(cid, speakerId)
    local m = OwnerSpeakerMap[cid]; if m then m[speakerId] = nil end
end
local function mapLookup(cid, speakerId)
    local m = OwnerSpeakerMap[cid]; if not m then return nil end
    return m[speakerId]
end
local function pickNextSpeakerId(cid)
    OwnerSpeakerMap[cid] = OwnerSpeakerMap[cid] or {}
    for i = 1, 999 do if OwnerSpeakerMap[cid][i] == nil then return i end end
    return nil
end

local function getLinkedNetIds(box)
    local list = {}
    for id, on in pairs(box.linkedIds or {}) do
        if on then
            local n = mapLookup(box.ownerCid, id)
            if n and ActiveBoxes[n] then list[#list + 1] = n end
        end
    end
    return list
end

local function canControl(src, netId)
    local box = ActiveBoxes[netId]
    if not box then return false, 'Box not found' end
    if not ServerCfg.AllowPublicControl then
        if box.owner ~= src then
            local Player = QBCore.Functions.GetPlayer(src)
            local cid = Player and Player.PlayerData.citizenid
            if cid and box.ownerCid and cid == box.ownerCid then
                box.owner = src
            else
                return false, 'Only owner can control'
            end
        end
    end
    if box.carried and box.owner == src then return true end
    local p = getCoords(src); if not p then return false, 'Invalid player' end
    local ref = box.coords
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent and DoesEntityExist(ent) then
        local epos = GetEntityCoords(ent); if epos then ref = epos end
    end
    if not ref or not isNear(p, ref, ServerCfg.ControlRadius + 2.0) then
        return false, 'Too far from boombox'
    end
    return true
end

for itemName, model in pairs(ServerCfg.Items or {}) do
    QBCore.Functions.CreateUseableItem(itemName, function(source)
        TriggerClientEvent('tk_bb:cl:useBoombox', source, model, itemName)
    end)
end

RegisterNetEvent('tk_bb:sv:registerBox', function(netId, coords, model, itemName)
    local src = source
    if not netId or not coords then return end
    local Player = QBCore.Functions.GetPlayer(src); if not Player then return end

    if not (itemName and ServerCfg.Items and ServerCfg.Items[itemName]) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'Item tidak valid' })
    end
    local expectedModel = ServerCfg.Items[itemName]
    if model ~= expectedModel then model = expectedModel end

    if ServerCfg.OneActivePerPlayer then
        for _, box in pairs(ActiveBoxes) do
            if box.owner == src then
                return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'Kamu sudah punya boombox aktif' })
            end
        end
    end

    if not Player.Functions.GetItemByName(itemName) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'Item tidak ditemukan' })
    end
    Player.Functions.RemoveItem(itemName, 1)

    local cid = Player.PlayerData.citizenid
    local dbId = dbCreateBox(cid, coords, nil, 0.5, 25, false, model)

    local speakerId = pickNextSpeakerId(cid) or 1
    mapBind(cid, speakerId, netId)

    ActiveBoxes[netId] = {
        dbId = dbId,
        owner = src,
        ownerCid = cid,
        coords = vec3(coords.x, coords.y, coords.z),
        model = model,
        playing = false,
        link = nil,
        volume = 0.5,
        distance = 25,
        carried = false,
        carrier = nil,
        queue = {},
        speakerId = speakerId,
        linkedIds = {},
    }

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Boombox', description = ('Speaker ID kamu: %d'):format(speakerId) })
end)

RegisterNetEvent('tk_bb:sv:registerBoxRestored', function(netId, payload)
    if not netId or not payload or not payload.coords or not payload.dbId then return end
    local cid = payload.ownerCid
    local speakerId = pickNextSpeakerId(cid) or 1
    mapBind(cid, speakerId, netId)

    ActiveBoxes[netId] = {
        dbId = payload.dbId,
        owner = 0,
        ownerCid = cid,
        coords = vec3(payload.coords.x, payload.coords.y, payload.coords.z),
        model = payload.model or 'prop_boombox_01',
        playing = payload.playing and (payload.link ~= nil) or false,
        link = payload.link,
        volume = payload.volume or 0.5,
        distance = payload.distance or 25,
        carried = false,
        carrier = nil,
        queue = {},
        speakerId = speakerId,
        linkedIds = {},
    }
    if ActiveBoxes[netId].playing then
        TriggerClientEvent('tk_bb:cl:applySound', -1, 'play', netId, {
            coords = payload.coords,
            link = ActiveBoxes[netId].link,
            volume = ActiveBoxes[netId].volume,
            distance = ActiveBoxes[netId].distance
        })
    end
end)

local function applyToLinks(box, fnName, data)
    local targets = getLinkedNetIds(box)
    if fnName == 'play' then
        for _, nid in ipairs(targets) do
            local b = ActiveBoxes[nid]
            if b then
                b.link, b.volume, b.distance, b.playing = data.link, data.volume, data.distance, true
                TriggerClientEvent('tk_bb:cl:applySound', -1, 'play', nid, {
                    coords = { x = b.coords.x, y = b.coords.y, z = b.coords.z },
                    link = b.link, volume = b.volume, distance = b.distance,
                    fadeMs = data.fadeMs or 300, delayMs = b.latencyMs or 0
                })
                dbUpdateBox(b.dbId, { link = b.link, volume = b.volume, distance = b.distance, playing = 1 })
            end
        end
    elseif fnName == 'stop' then
        for _, nid in ipairs(targets) do
            local b = ActiveBoxes[nid]; if b then b.playing = false end
            TriggerClientEvent('tk_bb:cl:applySound', -1, 'stop', nid, { fadeMs = (data and data.fadeMs) or 250 })
            if b then dbUpdateBox(b.dbId, { playing = 0 }) end
        end
    elseif fnName == 'volume' then
        for _, nid in ipairs(targets) do
            local b = ActiveBoxes[nid]; if b then b.volume = data.volume end
            TriggerClientEvent('tk_bb:cl:applySound', -1, 'volume', nid, { volume = data.volume })
            if b then dbUpdateBox(b.dbId, { volume = data.volume }) end
        end
    elseif fnName == 'distance' then
        for _, nid in ipairs(targets) do
            local b = ActiveBoxes[nid]; if b then b.distance = data.distance end
            TriggerClientEvent('tk_bb:cl:applySound', -1, 'distance', nid, { distance = data.distance })
            if b then dbUpdateBox(b.dbId, { distance = data.distance }) end
        end
    end
end

local BoxCooldown = {}

local function hitCooldown(netId, key, ms)
    BoxCooldown[netId] = BoxCooldown[netId] or {}
    local now = GetGameTimer()
    local last = BoxCooldown[netId][key] or 0
    if now - last < ms then return true end
    BoxCooldown[netId][key] = now
    return false
end

local function doStop(netId, opts)
    opts = opts or {}
    local box = ActiveBoxes[netId]; if not box then return end
    box.playing = false
    TriggerClientEvent('tk_bb:cl:applySound', -1, 'stop', netId, { fadeMs = opts.fadeMs or 250 })
    dbUpdateBox(box.dbId, { playing = 0 })
    applyToLinks(box, 'stop', { fadeMs = opts.fadeMs or 250 })
end

local function doPlay(netId, link, volume, distance, opts)
    opts = opts or {}
    local box = ActiveBoxes[netId]; if not box then return end
    volume = clamp(tonumber(volume) or 0.5, 0.0, 1.0)
    distance = math.floor(clamp(tonumber(distance) or 25, 1.0, 80.0))

    box.link, box.volume, box.distance, box.playing = link, volume, distance, true
    TriggerClientEvent('tk_bb:cl:applySound', -1, 'play', netId, {
        coords = { x = box.coords.x, y = box.coords.y, z = box.coords.z },
        link = link, volume = volume, distance = distance,
        fadeMs = opts.fadeMs or 300, delayMs = box.latencyMs or 0
    })
    dbUpdateBox(box.dbId, { link = link, volume = volume, distance = distance, playing = 1 })

    applyToLinks(box, 'play', { link = link, volume = volume, distance = distance, fadeMs = opts.fadeMs or 300 })
end

RegisterNetEvent('tk_bb:sv:play', function(netId, link, volume, distance)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = msg })
    end
    if hitCooldown(netId, 'playAt', 1000) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'Cooldown 1s' })
    end

    if ServerCfg.AllowedDomains and #ServerCfg.AllowedDomains > 0 then
        local okDomain, l = false, string.lower(link or '')
        for _, d in ipairs(ServerCfg.AllowedDomains) do
            if string.find(l, string.lower(d), 1, true) then okDomain = true break end
        end
        if not okDomain then
            return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'Link tidak diizinkan' })
        end
    end

    doPlay(netId, link, volume, distance, { fadeMs = 300 })
end)

RegisterNetEvent('tk_bb:sv:stop', function(netId)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = msg })
    end
    doStop(netId, { fadeMs = 250 })
end)

RegisterNetEvent('tk_bb:sv:volume', function(netId, volume)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = msg }) end
    local box = ActiveBoxes[netId]; if not box then return end
    volume = clamp(tonumber(volume) or box.volume, 0.0, 1.0)
    box.volume = volume
    TriggerClientEvent('tk_bb:cl:applySound', -1, 'volume', netId, { volume = volume })
    dbUpdateBox(box.dbId, { volume = volume })
    applyToLinks(box, 'volume', { volume = volume })
end)

RegisterNetEvent('tk_bb:sv:distance', function(netId, distance)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = msg }) end
    local box = ActiveBoxes[netId]; if not box then return end
    distance = math.floor(clamp(tonumber(distance) or box.distance, 1.0, 80.0))
    box.distance = distance
    TriggerClientEvent('tk_bb:cl:applySound', -1, 'distance', netId, { distance = distance })
    dbUpdateBox(box.dbId, { distance = distance })
    applyToLinks(box, 'distance', { distance = distance })
end)

local function isVipServer(src)
    local ok, res = pcall(function() return exports['tk_modul']:getVip(src) end)
    return ok and (res == true) or false
end

RegisterNetEvent('tk_bb:sv:setCarried', function(netId, state)
    local src = source
    if not isVipServer(src) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'Fitur ini khusus VIP' })
    end
    local ok, msg = canControl(src, netId)
    if not ok then return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = msg }) end
    local box = ActiveBoxes[netId]; if not box then return end

    state = not not state
    if state then
        box.carried = true; box.carrier = src
        TriggerClientEvent('tk_bb:cl:startCarry', src, netId)
        broadcast('tk_bb:cl:setCarried', netId, true, box.owner)
    else
        if box.carrier then TriggerClientEvent('tk_bb:cl:stopCarry', box.carrier, netId) end
        box.carried = false; box.carrier = nil
        broadcast('tk_bb:cl:setCarried', netId, false, box.owner)
    end
end)

RegisterNetEvent('tk_bb:sv:updateCoords', function(netId, coords)
    local src = source
    local box = ActiveBoxes[netId]; if not box then return end
    if box.owner ~= src then
        local Player = QBCore.Functions.GetPlayer(src)
        local cid = Player and Player.PlayerData.citizenid
        if cid and box.ownerCid and cid == box.ownerCid then box.owner = src else return end
    end
    if not coords then return end
    box.coords = vec3(coords.x, coords.y, coords.z)
    dbUpdateBox(box.dbId, { x = coords.x, y = coords.y, z = coords.z })
end)

RegisterNetEvent('tk_bb:sv:pickup', function(netId)
    local src = source
    local box = ActiveBoxes[netId]; if not box then return end

    if box.owner ~= src then
        local Player = QBCore.Functions.GetPlayer(src)
        local cid = Player and Player.PlayerData.citizenid
        if not (cid and box.ownerCid and cid == box.ownerCid) then
            return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'Hanya owner yang bisa mengambil' })
        end
        box.owner = src
    end

    TriggerClientEvent('tk_bb:cl:applySound', -1, 'stop', netId, {})
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
    SetTimeout(300, function()
        local ent2 = NetworkGetEntityFromNetworkId(netId)
        if ent2 and DoesEntityExist(ent2) then TriggerClientEvent('tk_bb:cl:requestDelete', -1, netId) end
    end)

    mapUnbind(box.ownerCid, box.speakerId)
    for id, _ in pairs(box.linkedIds or {}) do
        local net2 = mapLookup(box.ownerCid, id)
        if net2 and ActiveBoxes[net2] then
            ActiveBoxes[net2].linkedIds = ActiveBoxes[net2].linkedIds or {}
            ActiveBoxes[net2].linkedIds[box.speakerId] = nil
        end
    end

    dbDeleteBox(box.dbId)
    ActiveBoxes[netId] = nil

    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local itemName = ModelToItem[box.model] or 'boombox'
        Player.Functions.AddItem(itemName, 1)
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Boombox', description = 'Boombox diambil' })
end)

RegisterNetEvent('tk_bb:sv:requestSync', function()
    TriggerClientEvent('tk_bb:cl:syncAll', source, ActiveBoxes)
end)

local function scheduleWipeForCid(cid)
    if not cid then return end
    local token = (PendingWipes[cid] or 0) + 1
    PendingWipes[cid] = token
    SetTimeout((ServerCfg.RelogGraceMinutes or 30) * 60 * 1000, function()
        if PendingWipes[cid] ~= token then return end
        MySQL.update(([[DELETE FROM `%s` WHERE owner_cid = ?]]):format(T_BOX), { cid })
        PendingWipes[cid] = nil
    end)
end

AddEventHandler('playerDropped', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local cid = Player and Player.PlayerData.citizenid
    if not cid then for _, box in pairs(ActiveBoxes) do if box.owner == src and box.ownerCid then cid = box.ownerCid break end end end

    local remove = {}
    for netId, box in pairs(ActiveBoxes) do
        if box.owner == src or (cid and box.ownerCid == cid) then
            TriggerClientEvent('tk_bb:cl:applySound', -1, 'stop', netId, {})
            local ent = NetworkGetEntityFromNetworkId(netId); if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
            mapUnbind(box.ownerCid, box.speakerId)
            for id, _ in pairs(box.linkedIds or {}) do
                local net2 = mapLookup(box.ownerCid, id)
                if net2 and ActiveBoxes[net2] then ActiveBoxes[net2].linkedIds[box.speakerId] = nil end
            end
            remove[#remove + 1] = netId
        end
    end
    for _, id in ipairs(remove) do ActiveBoxes[id] = nil end
    if cid then scheduleWipeForCid(cid) end
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if not Player or not Player.PlayerData then return end
    local src = Player.PlayerData.source
    local cid = Player.PlayerData.citizenid
    if not cid then return end
    PendingWipes[cid] = (PendingWipes[cid] or 0) + 1
    local saved = dbListBoxesByCid(cid)
    if saved and #saved > 0 then TriggerClientEvent('tk_bb:cl:restoreSpawn', src, saved) end
end)

CreateThread(function()
    if ServerCfg.WipeOnResourceStart then
        MySQL.update(("DELETE FROM `%s`"):format(T_BOX))
        print(('[tk_boombox] Wipe on start: cleared %s'):format(T_BOX))
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for netId, _ in pairs(ActiveBoxes) do
        TriggerClientEvent('tk_bb:cl:applySound', -1, 'stop', netId, {})
        local ent = NetworkGetEntityFromNetworkId(netId); if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    if ServerCfg.WipeOnResourceStop then
        MySQL.update(("DELETE FROM `%s`"):format(T_BOX))
        print(('[tk_boombox] Wipe on stop: cleared %s'):format(T_BOX))
    end
end)

local function ensureQueue(box) box.queue = box.queue or {} return box.queue end
local function queueAdd(box, title, url) local q = ensureQueue(box); if #q >= 10 then return false, 'Playlist full (max 10)' end; q[#q + 1] = { title = title or url, url = url }; return true end
local function queueRemove(box, idx) local q = ensureQueue(box); if not q[idx] then return false end; table.remove(q, idx); return true end
local function queuePop(box) local q = ensureQueue(box); if #q == 0 then return nil end; return table.remove(q, 1) end
local function queueList(box) return ensureQueue(box) end

RegisterNetEvent('tk_bb:sv:queue:add', function(netId, title, url)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then return end
    local box = ActiveBoxes[netId]; if not box then return end
    local okAdd, err = queueAdd(box, title, url)
    if not okAdd then return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Playlist', description = err or 'Gagal tambah' }) end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Playlist', description = 'Ditambahkan ke antrian' })
end)

RegisterNetEvent('tk_bb:sv:queue:remove', function(netId, index)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then return end
    local box = ActiveBoxes[netId]; if not box then return end
    if queueRemove(box, tonumber(index) or -1) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Playlist', description = 'Dihapus dari antrian' })
    end
end)

RegisterNetEvent('tk_bb:sv:queue:playNow', function(netId, index)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Playlist', description = msg })
    end
    if hitCooldown(netId, 'nextAt', 1000) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Playlist', description = 'Cooldown 1s' })
    end

    local box = ActiveBoxes[netId]; if not box then return end
    local q = box.queue or {}
    local idx = tonumber(index or 0)
    local it = (idx and q[idx]) or nil
    if not it then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Playlist', description = 'Index tidak valid' })
    end

    table.remove(q, idx)
    doStop(netId, { fadeMs = 220 })
    SetTimeout(200, function()
        doPlay(netId, it.url, box.volume or 0.5, box.distance or 25, { fadeMs = 300 })
    end)
end)

RegisterNetEvent('tk_bb:sv:queue:next', function(netId)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Playlist', description = msg })
    end
    if hitCooldown(netId, 'nextAt', 1000) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Playlist', description = 'Cooldown 1s' })
    end

    local box = ActiveBoxes[netId]; if not box then return end
    local q = box.queue or {}
    if #q == 0 then
        return doStop(netId, { fadeMs = 220 })
    end

    local it = table.remove(q, 1)
    doStop(netId, { fadeMs = 220 })
    SetTimeout(200, function()
        doPlay(netId, it.url, box.volume or 0.5, box.distance or 25, { fadeMs = 300 })
    end)
end)

lib.callback.register('tk_bb:cb:getQueue', function(source, netId)
    local b = ActiveBoxes[netId]; if not b then return {} end
    return queueList(b)
end)

RegisterNetEvent('tk_bb:sv:songSave', function(name, url)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not name or name == '' or not url or url == '' then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'Data lagu tidak valid' })
    end
    local cid = Player.PlayerData.citizenid
    dbInsertSong(cid, name, url)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Boombox', description = 'Lagu disimpan' })
end)

RegisterNetEvent('tk_bb:sv:songDelete', function(id)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not id then return end
    local cid = Player.PlayerData.citizenid
    dbDeleteSong(cid, id)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Boombox', description = 'Lagu dihapus' })
end)

RegisterNetEvent('tk_bb:sv:latency', function(netId, delayMs)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = msg })
    end
    local box = ActiveBoxes[netId]; if not box then return end
    delayMs = math.floor(tonumber(delayMs) or 0)
    if delayMs < 0 then delayMs = 0 end
    if delayMs > 1000 then delayMs = 1000 end
    box.latencyMs = delayMs
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Boombox', description = ('Latency di-set %d ms'):format(delayMs) })
end)

lib.callback.register('tk_bb:cb:getSongs', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    local cid = Player and Player.PlayerData.citizenid
    if not cid then return {} end
    return dbListSongs(cid)
end)

lib.callback.register('tk_bb:cb:searchYoutube', function(source, query)
    if not ServerCfg.YouTube or not ServerCfg.YouTube.APIKey or ServerCfg.YouTube.APIKey == 'PUT_YOUR_YOUTUBE_API_KEY_HERE' then
        return { error = 'YouTube API key belum diisi di server/config.server.lua' }
    end
    if not query or query == '' then return {} end

    local encodedQuery = query:gsub(" ", "%%20")
    local url = string.format(
        "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=%d&q=%s&key=%s",
        ServerCfg.YouTube.MaxResults or 5, encodedQuery, ServerCfg.YouTube.APIKey
    )

    local p = promise.new()
    PerformHttpRequest(url, function(statusCode, response)
        if statusCode == 200 then
            local data = json.decode(response) or {}
            local items = {}
            if data.items then
                for _, it in ipairs(data.items) do
                    local vid = it.id and it.id.videoId
                    local title = it.snippet and it.snippet.title or 'Unknown'
                    local u = vid and ('https://www.youtube.com/watch?v=' .. vid) or nil
                    if u then
                        items[#items + 1] = {
                            id = vid,
                            title = title,
                            channel = it.snippet and it.snippet.channelTitle or '',
                            url = u,
                            publishedAt = it.snippet and it.snippet.publishedAt or '',
                            thumb = ('https://img.youtube.com/vi/%s/hqdefault.jpg'):format(vid)
                        }
                    end
                end
            end
            p:resolve(items)
        else
            print(('[tk_boombox] YouTube API failed (%s): %s'):format(statusCode, tostring(response)))
            p:resolve({})
        end
    end, "GET", "", { ["Content-Type"] = "application/json" })

    return Citizen.Await(p)
end)

RegisterNetEvent('tk_bb:sv:speaker:setId', function(netId, newId)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = msg }) end
    local box = ActiveBoxes[netId]; if not box then return end
    newId = tonumber(newId or 0); if not newId or newId < 1 or newId > 999 then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'ID harus 1-999' })
    end

    local cid = box.ownerCid
    local existingNet = mapLookup(cid, newId)
    local oldId = box.speakerId

    if existingNet and existingNet ~= netId then
        local other = ActiveBoxes[existingNet]
        if other then
            other.speakerId = oldId
            mapBind(cid, oldId, existingNet)
        else
            mapBind(cid, oldId, existingNet)
        end
    else
        mapUnbind(cid, oldId)
    end

    box.speakerId = newId
    mapBind(cid, newId, netId)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Boombox', description = ('Speaker ID di-set: %d'):format(newId) })
end)

RegisterNetEvent('tk_bb:sv:link:set', function(netId, csv)
    local src = source
    local box = ActiveBoxes[netId]; if not box then return end

    if not ServerCfg.AllowPublicControl then
        local Player = QBCore.Functions.GetPlayer(src)
        local cid = Player and Player.PlayerData.citizenid
        if not (cid and box.ownerCid and cid == box.ownerCid) then
            return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'Only owner can manage links' })
        end
        box.owner = src
    end

    local ids = parseIdsCSV(csv)
    local cid = box.ownerCid

    for id, _ in pairs(box.linkedIds or {}) do
        local n2 = mapLookup(cid, id)
        if n2 and ActiveBoxes[n2] then
            ActiveBoxes[n2].linkedIds = ActiveBoxes[n2].linkedIds or {}
            ActiveBoxes[n2].linkedIds[box.speakerId] = nil
        end
    end
    box.linkedIds = {}

    for _, id in ipairs(ids) do
        if id ~= box.speakerId then
            box.linkedIds[id] = true
            local n2 = mapLookup(cid, id)
            if n2 and ActiveBoxes[n2] then
                ActiveBoxes[n2].linkedIds = ActiveBoxes[n2].linkedIds or {}
                ActiveBoxes[n2].linkedIds[box.speakerId] = true
            end
        end
    end

    local cluster = { netId }
    for id, _ in pairs(box.linkedIds or {}) do
        local n2 = mapLookup(cid, id)
        if n2 and ActiveBoxes[n2] then cluster[#cluster + 1] = n2 end
    end

    local template = nil
    if (box.playing and box.link) then template = box end
    if not template then
        for _, nid in ipairs(cluster) do
            local b = ActiveBoxes[nid]
            if b and b.playing and b.link then template = b break end
        end
    end

    if not template then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Boombox', description = 'Koneksi diperbarui (tidak ada yang sedang memutar)' })
        return
    end

    local link = template.link
    local volume = template.volume or 0.5
    local distance = template.distance or 25

    for _, nid in ipairs(cluster) do
        TriggerClientEvent('tk_bb:cl:applySound', -1, 'stop', nid, {}) -- tanpa fade: pola lama
    end

    SetTimeout(120, function()
        for _, nid in ipairs(cluster) do
            local b = ActiveBoxes[nid]
            if b then
                b.link = link
                b.volume = volume
                b.distance = distance
                b.playing = true

                TriggerClientEvent('tk_bb:cl:applySound', -1, 'play', nid, {
                    coords = { x = b.coords.x, y = b.coords.y, z = b.coords.z },
                    link = link,
                    volume = volume,
                    distance = distance
                })

                dbUpdateBox(b.dbId, { link = link, volume = volume, distance = distance, playing = 1 })
            end
        end
    end)

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Boombox', description = 'Koneksi diperbarui & disinkronkan' })
end)

lib.callback.register('tk_bb:cb:getBoxMeta', function(source, netId)
    local b = ActiveBoxes[netId]
    if not b then return { speakerId = nil, links = {}, queueCount = 0 } end
    local list = {}
    for id, _ in pairs(b.linkedIds or {}) do list[#list + 1] = id end
    table.sort(list)
    return { speakerId = b.speakerId, links = list, queueCount = #(b.queue or {}) }
end)


QBCore.Commands.Add('bb_sweep', 'Boombox sweep (stop & cleanup) dalam radius', { { name = 'radius', help = 'meter' } }, false, function(src, args)
    local Player = QBCore.Functions.GetPlayer(src)
    local isAdmin = QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god') or IsPlayerAceAllowed(src, 'command.bb_sweep')
    if not isAdmin then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Boombox', description = 'No permission' })
    end

    local radius = tonumber(args[1]) or 50.0
    local p = getCoords(src); if not p then return end

    local cleaned = 0
    for netId, box in pairs(ActiveBoxes) do
        if #(p - box.coords) <= radius then
            TriggerClientEvent('tk_bb:cl:applySound', -1, 'stop', netId, { fadeMs = 200 })
            local ent = NetworkGetEntityFromNetworkId(netId); if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
            dbDeleteBox(box.dbId)
            cleaned = cleaned + 1
            ActiveBoxes[netId] = nil
        end
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Boombox', description = ('Disapu %d speaker'):format(cleaned) })
end)