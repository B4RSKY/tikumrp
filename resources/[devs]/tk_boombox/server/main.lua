local QBCore = exports['qb-core']:GetCoreObject()
local ActiveBoxes = {}
local PendingWipes = {}

local function isNear(a, b, r) return #(a - b) <= r end

local function getCoords(src)
    local ped = GetPlayerPed(src)
    if ped ~= 0 then return GetEntityCoords(ped) end
end

local function broadcast(ev, ...)
    TriggerClientEvent(ev, -1, ...)
end

local function clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

local T_BOX  = ServerCfg.DB.TableBoxes
local T_SONG = ServerCfg.DB.TableSongs

local function dbCreateBox(ownerCid, coords, link, volume, distance, playing)
    local sql = ("INSERT INTO `%s` (owner_cid, x, y, z, link, volume, distance, playing) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"):format(T_BOX)
    local id = MySQL.insert.await(sql, {
        ownerCid, coords.x, coords.y, coords.z,
        link or nil,
        volume or 0.5,
        distance or 25,
        playing and 1 or 0
    })
    return id
end

local function dbUpdateBox(id, fields)
    if not id or not fields then return end
    local sets, params = {}, {}
    for k, v in pairs(fields) do sets[#sets+1] = ("%s = ?"):format(k); params[#params+1] = v end
    params[#params+1] = id
    local q = ("UPDATE `%s` SET %s WHERE id = ?"):format(T_BOX, table.concat(sets, ", "))
    MySQL.update(q, params)
end

local function dbDeleteBox(id)
    if id then MySQL.update(("DELETE FROM `%s` WHERE id = ?"):format(T_BOX), { id }) end
end

local function dbListBoxesByCid(cid)
    local rows = MySQL.query.await(([[SELECT id, owner_cid, x, y, z, link, volume, distance, playing FROM `%s` WHERE owner_cid = ?]]):format(T_BOX), { cid }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        out[#out+1] = {
            id        = r.id,
            ownerCid  = r.owner_cid,
            coords    = { x = r.x, y = r.y, z = r.z },
            link      = r.link,
            volume    = r.volume or 0.5,
            distance  = r.distance or 25,
            playing   = r.playing == 1
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
            return false, 'Hanya pemilik yang dapat mengontrol'
        end
        end
    end

    if box.carried and box.owner == src then
        return true
    end

    local p = getCoords(src); if not p then return false, 'Invalid player' end
    local ref = box.coords
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent and DoesEntityExist(ent) then
        local epos = GetEntityCoords(ent)
        if epos then ref = epos end
    end

    if not ref or not isNear(p, ref, ServerCfg.ControlRadius + 2.0) then
        return false, 'Too far from boombox'
    end
    return true
end

QBCore.Functions.CreateUseableItem(ServerCfg.ItemName, function(source)
  TriggerClientEvent('tk_bb:cl:useBoombox', source)
end)

RegisterNetEvent('tk_bb:sv:registerBox', function(netId, coords)
    local src = source
    if not netId or not coords then return end
    local Player = QBCore.Functions.GetPlayer(src); if not Player then return end

    if ServerCfg.OneActivePerPlayer then
        for _, box in pairs(ActiveBoxes) do
        if box.owner == src then
            return TriggerClientEvent('ox_lib:notify', src, {type='error', title='Boombox', description='Kamu sudah punya boombox aktif'})
        end
        end
    end

    if not Player.Functions.GetItemByName(ServerCfg.ItemName) then
        return TriggerClientEvent('ox_lib:notify', src, {type='error', title='Boombox', description='Item tidak ditemukan'})
    end
    Player.Functions.RemoveItem(ServerCfg.ItemName, 1)

    local cid = Player.PlayerData.citizenid
    local dbId = dbCreateBox(cid, coords, nil, 0.5, 25, false)

    ActiveBoxes[netId] = {
        dbId     = dbId,
        owner    = src,
        ownerCid = cid,
        coords   = vec3(coords.x, coords.y, coords.z),
        playing  = false,
        link     = nil,
        volume   = 0.5,
        distance = 25,
        carried  = false,
        carrier  = nil,
    }

    TriggerClientEvent('ox_lib:notify', src, {type='success', title='Boombox', description='Boombox diletakkan'})
end)

RegisterNetEvent('tk_bb:sv:registerBoxRestored', function(netId, payload)
    if not netId or not payload or not payload.coords or not payload.dbId then return end
    ActiveBoxes[netId] = {
        dbId     = payload.dbId,
        owner    = 0, -- rebind saat kontrol
        ownerCid = payload.ownerCid,
        coords   = vec3(payload.coords.x, payload.coords.y, payload.coords.z),
        playing  = payload.playing and (payload.link ~= nil) or false,
        link     = payload.link,
        volume   = payload.volume or 0.5,
        distance = payload.distance or 25,
        carried  = false,
        carrier  = nil,
    }
    if ActiveBoxes[netId].playing then
        TriggerClientEvent('tk_bb:cl:applySound', -1, 'play', netId, {
        coords = payload.coords,
        link   = ActiveBoxes[netId].link,
        volume = ActiveBoxes[netId].volume,
        distance = ActiveBoxes[netId].distance
        })
    end
end)

RegisterNetEvent('tk_bb:sv:play', function(netId, link, volume, distance)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then return TriggerClientEvent('ox_lib:notify', src, {type='error', title='Boombox', description=msg}) end
    local box = ActiveBoxes[netId]; if not box then return end

    volume   = clamp(tonumber(volume) or 0.5, 0.0, 1.0)
    distance = math.floor(clamp(tonumber(distance) or 25, 1.0, 80.0))

    if ServerCfg.AllowedDomains and #ServerCfg.AllowedDomains > 0 then
        local okDomain = false
        local l = string.lower(link or '')
        for _, d in ipairs(ServerCfg.AllowedDomains) do
        if string.find(l, string.lower(d), 1, true) then okDomain = true break end
        end
        if not okDomain then
        return TriggerClientEvent('ox_lib:notify', src, {type='error', title='Boombox', description='Link tidak diizinkan'})
        end
    end

    box.link, box.volume, box.distance, box.playing = link, volume, distance, true
    TriggerClientEvent('tk_bb:cl:applySound', -1, 'play', netId, {
        coords = { x = box.coords.x, y = box.coords.y, z = box.coords.z },
        link = link, volume = volume, distance = distance
    })

    dbUpdateBox(box.dbId, { link = link, volume = volume, distance = distance, playing = 1 })
end)

RegisterNetEvent('tk_bb:sv:stop', function(netId)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then return TriggerClientEvent('ox_lib:notify', src, {type='error', title='Boombox', description=msg}) end
    local box = ActiveBoxes[netId]; if not box then return end
    box.playing = false
    TriggerClientEvent('tk_bb:cl:applySound', -1, 'stop', netId, {})
    dbUpdateBox(box.dbId, { playing = 0 })
end)

RegisterNetEvent('tk_bb:sv:volume', function(netId, volume)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then return TriggerClientEvent('ox_lib:notify', src, {type='error', title='Boombox', description=msg}) end
    local box = ActiveBoxes[netId]; if not box then return end
    volume = clamp(tonumber(volume) or box.volume, 0.0, 1.0)
    box.volume = volume
    TriggerClientEvent('tk_bb:cl:applySound', -1, 'volume', netId, { volume = volume })
    dbUpdateBox(box.dbId, { volume = volume })
end)

RegisterNetEvent('tk_bb:sv:distance', function(netId, distance)
    local src = source
    local ok, msg = canControl(src, netId); if not ok then return TriggerClientEvent('ox_lib:notify', src, {type='error', title='Boombox', description=msg}) end
    local box = ActiveBoxes[netId]; if not box then return end
    distance = math.floor(clamp(tonumber(distance) or box.distance, 1.0, 80.0))
    box.distance = distance
    TriggerClientEvent('tk_bb:cl:applySound', -1, 'distance', netId, { distance = distance })
    dbUpdateBox(box.dbId, { distance = distance })
end)

RegisterNetEvent('tk_bb:sv:setCarried', function(netId, state)
    local src = source
    local ok, msg = canControl(src, netId)
    if not ok then return TriggerClientEvent('ox_lib:notify', src, {type='error', title='Boombox', description=msg}) end
    local box = ActiveBoxes[netId]; if not box then return end

    state = not not state
    if state then
        box.carried = true
        box.carrier = src
        TriggerClientEvent('tk_bb:cl:startCarry', src, netId)
        broadcast('tk_bb:cl:setCarried', netId, true, box.owner)
    else
        if box.carrier then TriggerClientEvent('tk_bb:cl:stopCarry', box.carrier, netId) end
        box.carried = false
        box.carrier = nil
        broadcast('tk_bb:cl:setCarried', netId, false, box.owner)
    end
end)

RegisterNetEvent('tk_bb:sv:updateCoords', function(netId, coords)
    local src = source
    local box = ActiveBoxes[netId]; if not box then return end
    if box.owner ~= src then
        local Player = QBCore.Functions.GetPlayer(src)
        local cid = Player and Player.PlayerData.citizenid
        if cid and box.ownerCid and cid == box.ownerCid then
        box.owner = src
        else
        return
        end
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
        return TriggerClientEvent('ox_lib:notify', src, {type='error', title='Boombox', description='Hanya owner yang bisa mengambil'})
        end
        box.owner = src
    end

    TriggerClientEvent('tk_bb:cl:applySound', -1, 'stop', netId, {})
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
    SetTimeout(300, function()
        local ent2 = NetworkGetEntityFromNetworkId(netId)
        if ent2 and DoesEntityExist(ent2) then
        TriggerClientEvent('tk_bb:cl:requestDelete', -1, netId)
        end
    end)

    dbDeleteBox(box.dbId)
    ActiveBoxes[netId] = nil

    local Player = QBCore.Functions.GetPlayer(src)
    if Player then Player.Functions.AddItem(ServerCfg.ItemName, 1) end
    TriggerClientEvent('ox_lib:notify', src, {type='success', title='Boombox', description='Boombox diambil'})
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

    if not cid then
        for _, box in pairs(ActiveBoxes) do
        if box.owner == src and box.ownerCid then cid = box.ownerCid break end
        end
    end

    local remove = {}
    for netId, box in pairs(ActiveBoxes) do
        if box.owner == src or (cid and box.ownerCid == cid) then
        TriggerClientEvent('tk_bb:cl:applySound', -1, 'stop', netId, {})
        local ent = NetworkGetEntityFromNetworkId(netId)
        if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
        remove[#remove+1] = netId
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
    if saved and #saved > 0 then
        TriggerClientEvent('tk_bb:cl:restoreSpawn', src, saved)
    end
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
        local ent = NetworkGetEntityFromNetworkId(netId)
        if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    if ServerCfg.WipeOnResourceStop then
        MySQL.update(("DELETE FROM `%s`"):format(T_BOX))
        print(('[tk_boombox] Wipe on stop: cleared %s'):format(T_BOX))
    end
end)

RegisterNetEvent('tk_bb:sv:songSave', function(name, url)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not name or name == '' or not url or url == '' then
        return TriggerClientEvent('ox_lib:notify', src, {type='error', title='Boombox', description='Data lagu tidak valid'})
    end
    local cid = Player.PlayerData.citizenid
    dbInsertSong(cid, name, url)
    TriggerClientEvent('ox_lib:notify', src, {type='success', title='Boombox', description='Lagu disimpan'})
end)

RegisterNetEvent('tk_bb:sv:songDelete', function(id)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not id then return end
    local cid = Player.PlayerData.citizenid
    dbDeleteSong(cid, id)
    TriggerClientEvent('ox_lib:notify', src, {type='success', title='Boombox', description='Lagu dihapus'})
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
                    local u = vid and ('https://www.youtube.com/watch?v='..vid) or nil
                    if u then
                        items[#items+1] = {
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