local xSound = exports.xsound

local function joaat_try(name)
    if type(name) == 'string' then
        return joaat(name)
    else
        return name
    end
end

local function loadModel(nameOrHash)
    local hash = joaat_try(nameOrHash)
    if not IsModelValid(hash) then
        return false
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then
            return false
        end
    end
    return hash
end

local function putOnGround(ent)
    PlaceObjectOnGroundProperly(ent)
    FreezeEntityPosition(ent, true)
    SetEntityAsMissionEntity(ent, true, false)
end

local function makeMusicId(netId)
    return ('bb_%s'):format(netId)
end

local function ytIdFromUrl(u)
    if not u then
        return nil
    end
    return u:match("[?&]v=([%w-_]+)") or u:match("youtu%.be/([%w-_]+)") or u:match("youtube%.com/shorts/([%w-_]+)") or u:match("youtube%.com/embed/([%w-_]+)")
end

local function ytThumb(u)
    local id = ytIdFromUrl(u)
    if id then
        return ('https://img.youtube.com/vi/%s/hqdefault.jpg'):format(id)
    end
end

local function isVip()
    local ok, res = pcall(function()
        return exports['tk_modul']:getVip()
    end)
    return ok and (res == true) or false
end

local placing = false
local Boxes = {}
local Carried = {}
local LocalCarry = {
    netId = nil,
    entity = 0
}

local LocalVolumeMult = GetResourceKvpFloat('tk_bb_myvol')
if not LocalVolumeMult or LocalVolumeMult <= 0.0 then
    LocalVolumeMult = 1.0
end

local function effectiveVolume(base)
    local v = (base or ClientCfg.DefaultVolume) * (LocalVolumeMult or 1.0)
    if v > ClientCfg.MaxVolume then
        v = ClientCfg.MaxVolume
    end
    if v < 0.0 then
        v = 0.0
    end
    return v
end

local function applyAllEffectiveVolumes()
    for netId, box in pairs(Boxes or {}) do
        if box.playing then
            local id = makeMusicId(netId)
            if xSound:soundExists(id) then
                xSound:setVolume(id, effectiveVolume(box.volume or ClientCfg.DefaultVolume))
            end
        end
    end
end

local function tryCopyToClipboard(text)
    if not text or text == '' then
        return
    end
    if lib and lib.setClipboard then
        lib.setClipboard(text)
        lib.notify({
            type = 'success',
            title = 'Clipboard',
            description = 'URL tersalin'
        })
    else
        lib.notify({
            type = 'error',
            title = 'Clipboard',
            description = 'Clipboard tidak tersedia di client ini'
        })
    end
end

CreateThread(function()
    local entries = {}
    for _, name in ipairs(ClientCfg.Models or {}) do
        local hash = joaat_try(name)
        if IsModelValid(hash) then
            entries[#entries + 1] = hash
        end
    end
    if #entries == 0 then
        entries = {
            joaat_try(ClientCfg.DefaultModel)
        }
    end

    exports.ox_target:addModel(entries, {
        {
            icon = 'fa-solid fa-music',
            label = 'Boombox',
            distance = 2.0,
            onSelect = function(data)
                local ent = data.entity
                if not ent or not DoesEntityExist(ent) then
                    return
                end
                local netId = NetworkGetNetworkIdFromEntity(ent)
                OpenBoomboxMenu(ent, netId)
            end
        }
    })
end)

local function openSavedSongsMenu(netId)
    local songs = lib.callback.await('tk_bb:cb:getSongs', false) or {}
    if #songs == 0 then
        return lib.notify({
            type = 'inform',
            title = 'Boombox',
            description = 'Saved songs kosong'
        })
    end
    local options = {}
    for _, s in ipairs(songs) do
        options[#options + 1] = {
            title = s.name,
            description = s.url,
            icon = 'fa-solid fa-music',
            onSelect = function()
                lib.registerContext({
                    id = 'tk_bb_menu_song_' .. s.id,
                    title = s.name,
                    options = {
                        {
                            title = 'Play',
                            icon = 'fa-solid fa-play',
                            onSelect = function()
                                TriggerServerEvent('tk_bb:sv:play', netId, s.url, Boxes[netId] and Boxes[netId].volume or ClientCfg.DefaultVolume, Boxes[netId] and Boxes[netId].distance or ClientCfg.DefaultDistance)
                            end
                        },
                        {
                            title = 'Tambahkan Ke Playlist',
                            icon = 'fa-solid fa-list',
                            onSelect = function()
                                TriggerServerEvent('tk_bb:sv:queue:add', netId, s.name, s.url)
                            end
                        },
                        {
                            title = 'Copy URL',
                            icon = 'fa-solid fa-copy',
                            onSelect = function()
                                tryCopyToClipboard(s.url)
                            end
                        },
                        {
                            title = 'Hapus musik',
                            icon = 'fa-solid fa-trash',
                            onSelect = function()
                                TriggerServerEvent('tk_bb:sv:songDelete', s.id)
                            end
                        },
                    }
                })
                lib.showContext('tk_bb_menu_song_' .. s.id)
            end
        }
    end
    lib.registerContext({
        id = 'tk_bb_menu_songs',
        title = 'Musik Tersimpan',
        options = options
    })
    lib.showContext('tk_bb_menu_songs')
end

local function openManagePlaylistMenu(netId)
    local q = lib.callback.await('tk_bb:cb:getQueue', false, netId) or {}
    local opts = {}
    if #q == 0 then
        opts[#opts + 1] = {
            title = '(Playlist kosong)',
            disabled = true
        }
    else
        for i, it in ipairs(q) do
            opts[#opts + 1] = {
                title = ('%d) %s'):format(i, it.title or it.url),
                description = it.url,
                icon = 'fa-solid fa-music',
                onSelect = function()
                    lib.registerContext({
                        id = 'tk_bb_menu_pl_item_' .. i,
                        title = it.title or it.url,
                        options = {
                            {
                                title = 'Play',
                                icon = 'fa-solid fa-play',
                                onSelect = function()
                                    TriggerServerEvent('tk_bb:sv:queue:playNow', netId, i)
                                end
                            },
                            {
                                title = 'Hapus',
                                icon = 'fa-solid fa-trash',
                                onSelect = function()
                                    TriggerServerEvent('tk_bb:sv:queue:remove', netId, i)
                                end
                            },
                        }
                    })
                    lib.showContext('tk_bb_menu_pl_item_' .. i)
                end
            }
        end
    end
    lib.registerContext({
        id = 'tk_bb_menu_manage_pl',
        title = 'Manage Playlist',
        options = opts
    })
    lib.showContext('tk_bb_menu_manage_pl')
end

local function openYouTubeSearchMenu(netId)
    local q = lib.inputDialog('YouTube Search', {
        {
            type = 'input',
            label = 'Ketik judul/keyword',
            required = true
        }
    })
    if not q then
        return
    end
    local vip = isVip()
    if not vip then
        return lib.notify({
            type = 'error',
            title = 'Boombox',
            description = 'Khusus VIP'
        })
    end
    local res = lib.callback.await('tk_bb:cb:searchYoutube', false, tostring(q[1])) or {}
    if res.error then
        return lib.notify({
            type = 'error',
            title = 'YouTube',
            description = res.error
        })
    end
    if #res == 0 then
        return lib.notify({
            type = 'inform',
            title = 'YouTube',
            description = 'Tidak ada hasil'
        })
    end

    local opts = {}
    for _, it in ipairs(res) do
        opts[#opts + 1] = {
            title = it.title,
            description = it.url,
            image = it.thumb,
            onSelect = function()
                lib.registerContext({
                    id = 'tk_bb_menu_yt_' .. it.id,
                    title = it.title,
                    options = {
                        {
                            title = 'Play',
                            icon = 'fa-solid fa-play',
                            onSelect = function()
                                TriggerServerEvent('tk_bb:sv:play', netId, it.url, Boxes[netId] and Boxes[netId].volume or ClientCfg.DefaultVolume, Boxes[netId] and Boxes[netId].distance or ClientCfg.DefaultDistance)
                            end
                        },
                        {
                            title = 'Tambahkan Ke Playlist',
                            icon = 'fa-solid fa-list',
                            onSelect = function()
                                TriggerServerEvent('tk_bb:sv:queue:add', netId, it.title, it.url)
                            end
                        },
                        {
                            title = 'Simpan Musik',
                            icon = 'fa-solid fa-bookmark',
                            onSelect = function()
                                TriggerServerEvent('tk_bb:sv:songSave', it.title, it.url)
                            end
                        },
                        {
                            title = 'Copy URL',
                            icon = 'fa-solid fa-copy',
                            onSelect = function()
                                tryCopyToClipboard(it.url)
                            end
                        },
                    }
                })
                lib.showContext('tk_bb_menu_yt_' .. it.id)
            end
        }
    end
    lib.registerContext({
        id = 'tk_bb_menu_yt',
        title = ('YouTube: %s'):format(tostring(q[1])),
        options = opts
    })
    lib.showContext('tk_bb_menu_yt')
end

local function openSettingsMenu(netId)
    local meta = lib.callback.await('tk_bb:cb:getBoxMeta', false, netId) or {
        speakerId = nil,
        links = {},
        queueCount = 0
    }
    local linksText = (#meta.links > 0) and table.concat(meta.links, ', ') or '(none)'

    local opts = {
        {
            title = 'Manage Playlist',
            description = 'Play now / remove',
            onSelect = function()
                openManagePlaylistMenu(netId)
            end
        },
        {
            title = 'Next Song',
            description = meta.queueCount > 0 and ('Skip to next (%d in queue)'):format(meta.queueCount) or '(Playlist kosong)',
            disabled = meta.queueCount == 0,
            onSelect = function()
                TriggerServerEvent('tk_bb:sv:queue:next', netId)
            end
        },
        {
            title = ('Speaker ID: %s'):format(meta.speakerId or '?'),
            description = 'Set custom ID (1-999)',
            onSelect = function()
                local inp = lib.inputDialog('Set Speaker ID', {
                    {
                        type = 'number',
                        label = 'ID (1-999)',
                        min = 1,
                        max = 999,
                        required = true,
                        default = meta.speakerId or 1
                    }
                })
                if not inp then
                    return
                end
                TriggerServerEvent('tk_bb:sv:speaker:setId', netId, tonumber(inp[1]))
            end
        },
        {
            title = ('Connected to: %s'):format(linksText),
            description = 'Isi ID target, pisahkan dengan koma (cth: 2,3,5)',
            onSelect = function()
                local inp = lib.inputDialog('Connect to IDs', {
                    {
                        type = 'input',
                        label = 'IDs (comma-separated)',
                        placeholder = '2,3,5'
                    }
                })
                if not inp then
                    return
                end
                TriggerServerEvent('tk_bb:sv:link:set', netId, tostring(inp[1] or ''))
            end
        },
        {
            title = 'Latency Offset (ms)',
            description = 'Kompensasi jeda per speaker (0-1000ms)',
            onSelect = function()
                local inp = lib.inputDialog('Latency Offset', {
                    {
                        type = 'number',
                        label = 'ms',
                        default = 0,
                        min = 0,
                        max = 1000
                    }
                })
                if not inp then
                    return
                end
                TriggerServerEvent('tk_bb:sv:latency', netId, tonumber(inp[1]) or 0)
            end
        },
    }
    lib.registerContext({
        id = 'tk_bb_menu_settings',
        title = 'Settings',
        options = opts
    })
    lib.showContext('tk_bb_menu_settings')
end

function OpenBoomboxMenu(entity, netId)
    local vip = isVip()
    local meta = lib.callback.await('tk_bb:cb:getBoxMeta', false, netId) or {
        speakerId = nil,
        links = {}
    }
    local linksText = (#meta.links > 0) and table.concat(meta.links, ', ') or 'none'

    local options = {
        {
            title = ('Speaker ID: %s  |  Connected: %s'):format(meta.speakerId or '?', linksText),
            disabled = true
        },
        {
            title = 'Play (paste URL)',
            description = 'Tempel link YouTube',
            icon = 'fa-solid fa-play',
            onSelect = function()
                local input = lib.inputDialog('Play Music', {
                    {
                        type = 'input',
                        label = 'URL (YouTube/SoundCloud)',
                        required = true
                    },
                    {
                        type = 'number',
                        label = ('Distance (max %d)'):format(ClientCfg.MaxDistance),
                        default = ClientCfg.DefaultDistance,
                        min = 1,
                        max = ClientCfg.MaxDistance
                    },
                    {
                        type = 'number',
                        label = 'Volume (0-100)',
                        default = math.floor(ClientCfg.DefaultVolume * 100),
                        min = 0,
                        max = 100
                    }
                })
                if not input then
                    return
                end
                local link, distance, volume = tostring(input[1]), tonumber(input[2]) or ClientCfg.DefaultDistance, (tonumber(input[3]) or math.floor(ClientCfg.DefaultVolume * 100)) / 100.0
                TriggerServerEvent('tk_bb:sv:play', netId, link, volume, distance)
            end
        },
        {
            title = 'Cari Di YouTube',
            description='Mencari Musik Langsung dari youtube (Khusus VIP)',
            icon = 'fa-brands fa-youtube',
            onSelect = function()
                openYouTubeSearchMenu(netId)
            end,
            disabled = not vip,
        },
        {
            title = 'Simpan Musik',
            icon = 'fa-solid fa-bookmark',
            onSelect = function()
                local input = lib.inputDialog('Simpan Musik', {
                    {
                        type = 'input',
                        label = 'Name',
                        required = true
                    },
                    {
                        type = 'input',
                        label = 'URL (YouTube/SoundCloud)',
                        required = true
                    }
                })
                if not input then
                    return
                end
                TriggerServerEvent('tk_bb:sv:songSave', tostring(input[1]), tostring(input[2]))
            end
        },
        {
            title = 'Musik Tersimpan',
            icon = 'fa-solid fa-music',
            onSelect = function()
                openSavedSongsMenu(netId)
            end
        },
        {
            title = 'Settings',
            icon = 'fa-solid fa-gear',
            description = 'Playlist, Konek Ke banyak Speaker (Khusus VIP)',
            onSelect = function()
                openSettingsMenu(netId)
            end,
            disabled = not vip,
        },
        {
            title = 'Stop',
            icon = 'fa-solid fa-stop',
            onSelect = function()
                TriggerServerEvent('tk_bb:sv:stop', netId)
            end
        },
        {
            title = 'Set Volume',
            icon = 'fa-solid fa-volume-high',
            description = 'Untuk setting Volume secara global (ke semua player)',
            onSelect = function()
                local v = lib.inputDialog('Volume', {
                    {
                        type = 'number',
                        label = 'Volume (0-100)',
                        default = math.floor((Boxes[netId] and Boxes[netId].volume or ClientCfg.DefaultVolume) * 100),
                        min = 0,
                        max = 100
                    }
                })
                if not v then
                    return
                end
                TriggerServerEvent('tk_bb:sv:volume', netId, (tonumber(v[1]) or 50) / 100.0)
            end
        },
        {
            title = 'Set Distance',
            icon = 'fa-solid fa-people-arrows',
            description='Untuk setting jarak secara global (ke semua player)',
            onSelect = function()
                local d = lib.inputDialog('Distance', {
                    {
                        type = 'number',
                        label = ('Distance (max %d)'):format(ClientCfg.MaxDistance),
                        default = Boxes[netId] and Boxes[netId].distance or ClientCfg.DefaultDistance,
                        min = 1,
                        max = ClientCfg.MaxDistance
                    }
                })
                if not d then
                    return
                end
                TriggerServerEvent('tk_bb:sv:distance', netId, tonumber(d[1]) or ClientCfg.DefaultDistance)
            end
        },
    }

    if ClientCfg.UI and ClientCfg.UI.ShowLocalVolume then
        local current = math.floor((LocalVolumeMult or 1.0) * 100)
        options[#options + 1] = {
            title = ('My Volume: %d%%'):format(current),
            icon = 'fa-solid fa-volume-high',
            description = 'Hanya setting volume di kamu saja (tidak di player lain)',
            onSelect = function()
                local input = lib.inputDialog('My Volume (Local Only)', {
                    {
                        type = 'number',
                        label = '0 - 100 (%)',
                        default = current,
                        min = 0,
                        max = 100
                    }
                })
                if not input then
                    return
                end
                LocalVolumeMult = (tonumber(input[1]) or current) / 100.0
                if LocalVolumeMult < 0.0 then
                    LocalVolumeMult = 0.0
                end
                if LocalVolumeMult > 1.0 then
                    LocalVolumeMult = 1.0
                end
                SetResourceKvpFloat('tk_bb_myvol', LocalVolumeMult)
                applyAllEffectiveVolumes()
                lib.notify({
                    type = 'success',
                    title = 'Boombox',
                    description = ('My Volume di-set %d%%'):format(math.floor(LocalVolumeMult * 100))
                })
            end
        }
    end

    options[#options + 1] = {
        title='Carry',
        icon = 'fa-solid fa-hand',
        description = 'Bisa dengerin musik sambil dibawa music box nya (Khusus VIP)',
        onSelect = function()
            if not vip then
                return
            end
            if ClientCfg.Carry.Enabled then
                TriggerServerEvent('tk_bb:sv:setCarried', netId, true)
            end
        end,
        disabled = not vip
    }
    options[#options + 1] = {
        title = 'Ambil',
        description = 'Masukkan ke inventory',
        icon = 'fa-solid fa-box',
        onSelect = function()
            TriggerServerEvent('tk_bb:sv:pickup', netId)
        end
    }

    lib.registerContext({
        id = 'tk_bb_menu_' .. netId,
        title = 'Boombox',
        options = options
    })
    lib.showContext('tk_bb_menu_' .. netId)
end

RegisterNetEvent('tk_bb:cl:useBoombox', function(modelName, itemName)
    if placing then
        return
    end
    placing = true

    local mdl = modelName or ClientCfg.DefaultModel
    local hash = loadModel(mdl)
    if not hash then
        lib.notify({
            type = 'error',
            title = 'Boombox',
            description = 'Model gagal dimuat'
        })
        placing = false
        return
    end

    local ped = PlayerPedId()
    local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.0)
    local heading = GetEntityHeading(ped)
    local obj = CreateObject(hash, pos.x, pos.y, pos.z, true, true, false)
    SetEntityHeading(obj, heading)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, false)

    local netId = NetworkGetNetworkIdFromEntity(obj)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)

    local coords = GetEntityCoords(obj)
    TriggerServerEvent('tk_bb:sv:registerBox', netId, {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }, modelName, itemName)

    SetModelAsNoLongerNeeded(hash)
    placing = false
end)

RegisterNetEvent('tk_bb:cl:syncAll', function(active)
    Boxes = active or {}
    for netId, box in pairs(Boxes) do
        if box.playing and box.link then
            local id = makeMusicId(netId)
            local pos = vector3(box.coords.x, box.coords.y, box.coords.z)
            if xSound:soundExists(id) then
                xSound:Destroy(id)
                Wait(25)
            end
            xSound:PlayUrlPos(id, box.link, effectiveVolume(box.volume or ClientCfg.DefaultVolume), pos)
            xSound:Distance(id, box.distance)
        end
        if box.carried then
            Carried[netId] = true
        end
    end
end)

RegisterNetEvent('tk_bb:cl:restoreSpawn', function(saved)
    if not saved or #saved == 0 then
        return
    end
    for _, box in ipairs(saved) do
        local mdl = box.model or ClientCfg.DefaultModel
        local hash = loadModel(mdl)
        if hash then
            local cx = (box.coords and box.coords.x) or box.x
            local cy = (box.coords and box.coords.y) or box.y
            local cz = (box.coords and box.coords.z) or box.z
            if cx and cy and cz then
                local obj = CreateObject(hash, cx, cy, cz, true, true, false)
                SetEntityHeading(obj, 0.0)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                SetEntityAsMissionEntity(obj, true, false)

                local netId = NetworkGetNetworkIdFromEntity(obj)
                SetNetworkIdExistsOnAllMachines(netId, true)
                SetNetworkIdCanMigrate(netId, true)

                TriggerServerEvent('tk_bb:sv:registerBoxRestored', netId, {
                    dbId = box.id,
                    coords = {
                        x = cx,
                        y = cy,
                        z = cz
                    },
                    link = box.link,
                    volume = box.volume,
                    distance = box.distance,
                    playing = box.playing,
                    ownerCid = box.ownerCid,
                    model = mdl
                })
            end
            SetModelAsNoLongerNeeded(hash)
        end
    end
end)

RegisterNetEvent('tk_bb:cl:applySound', function(action, netId, data)
    local id = makeMusicId(netId)
    data = data or {}
    local fadeMs = tonumber(data.fadeMs or 0) or 0
    local delayMs = tonumber(data.delayMs or 0) or 0

    if action == 'play' then
        local vec = data.coords and vector3(data.coords.x, data.coords.y, data.coords.z)
        if not vec then
            local ent = NetworkGetEntityFromNetworkId(netId)
            if ent and DoesEntityExist(ent) then
                vec = GetEntityCoords(ent)
            end
        end
        if not vec then
            return
        end

        CreateThread(function()
            if xSound:soundExists(id) then
                if fadeMs > 0 then
                    xSound:fadeOut(id, fadeMs)
                    Wait(fadeMs + 40)
                end
                xSound:Destroy(id)
                Wait(25)
            end

            if delayMs > 0 then
                Wait(delayMs)
            end

            local targetVol = effectiveVolume(data.volume or ClientCfg.DefaultVolume)
            xSound:PlayUrlPos(id, data.link, 0.0, vec)
            xSound:Distance(id, data.distance or ClientCfg.DefaultDistance)
            if fadeMs > 0 then
                xSound:fadeIn(id, fadeMs, targetVol)
            else
                xSound:setVolume(id, targetVol)
            end

            if xSound and type(xSound.onPlayEnd) == 'function' then
                local ok = pcall(function()
                    xSound:onPlayEnd(id, function()
                        TriggerServerEvent('tk_bb:sv:queue:next', netId)
                    end)
                end)
            end
        end)

    elseif action == 'stop' then
        if xSound:soundExists(id) then
            if fadeMs > 0 then
                xSound:fadeOut(id, fadeMs)
                CreateThread(function()
                    Wait(fadeMs + 40)
                    if xSound:soundExists(id) then
                        xSound:Destroy(id)
                    end
                end)
            else
                xSound:Destroy(id)
            end
        end

    elseif action == 'volume' then
        if xSound:soundExists(id) then
            xSound:setVolume(id, effectiveVolume(data.volume or ClientCfg.DefaultVolume))
        end

    elseif action == 'distance' then
        if xSound:soundExists(id) then
            xSound:Distance(id, data.distance or ClientCfg.DefaultDistance)
        end
    end
end)

RegisterNetEvent('tk_bb:cl:requestDelete', function(netId)
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent and DoesEntityExist(ent) then
        DeleteEntity(ent)
    end
end)

RegisterNetEvent('tk_bb:cl:setCarried', function(netId, state, owner)
    Boxes[netId] = Boxes[netId] or {}
    Boxes[netId].carried = state
    Boxes[netId].owner = owner or Boxes[netId].owner
    if state then
        Carried[netId] = true
    else
        Carried[netId] = nil
    end
end)

RegisterNetEvent('tk_bb:cl:startCarry', function(netId)
    if not ClientCfg.Carry.Enabled then
        return
    end
    local ent = NetworkGetEntityFromNetworkId(netId)
    if not ent or not DoesEntityExist(ent) then
        return
    end
    local ped = PlayerPedId()
    FreezeEntityPosition(ent, false)
    AttachEntityToEntity(ent, ped, GetPedBoneIndex(ped, ClientCfg.Carry.Bone),
        ClientCfg.Carry.Offset.x, ClientCfg.Carry.Offset.y, ClientCfg.Carry.Offset.z,
        ClientCfg.Carry.Rot.x, ClientCfg.Carry.Rot.y, ClientCfg.Carry.Rot.z,
        true, true, false, true, 1, true
    )
    if ClientCfg.Carry.AnimDict and ClientCfg.Carry.AnimName then
        RequestAnimDict(ClientCfg.Carry.AnimDict)
        while not HasAnimDictLoaded(ClientCfg.Carry.AnimDict) do
            Wait(0)
        end
        TaskPlayAnim(ped, ClientCfg.Carry.AnimDict, ClientCfg.Carry.AnimName, 8.0, 8.0, -1, 50, 0, false, false, false)
    end
    LocalCarry.netId = netId
    LocalCarry.entity = ent
end)

RegisterNetEvent('tk_bb:cl:stopCarry', function(netId)
    if LocalCarry.netId ~= netId then
        return
    end
    local ent = LocalCarry.entity
    if ent and DoesEntityExist(ent) then
        DetachEntity(ent, true, true)
        putOnGround(ent)
    end
    ClearPedTasks(PlayerPedId())
    local c = ent and GetEntityCoords(ent)
    if c then
        TriggerServerEvent('tk_bb:sv:updateCoords', netId, {
            x = c.x,
            y = c.y,
            z = c.z
        })
    end
    LocalCarry.netId, LocalCarry.entity = nil, 0
end)

CreateThread(function()
    while true do
        local wait = 500
        if LocalCarry.netId then
            wait = 0
            if ClientCfg.Carry.KeepPlaying and not IsEntityPlayingAnim(PlayerPedId(), ClientCfg.Carry.AnimDict, ClientCfg.Carry.AnimName, 3) then
                TaskPlayAnim(PlayerPedId(), ClientCfg.Carry.AnimDict, ClientCfg.Carry.AnimName, 8.0, 8.0, -1, 50, 0, false, false, false)
            end
            if ClientCfg.Carry.DisableSprint then
                DisableControlAction(0, 21, true)
            end
            if ClientCfg.Carry.DisableJump then
                DisableControlAction(0, 22, true)
            end
        end
        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        local any = false
        for netId, _ in pairs(Carried) do
            any = true
            local id = makeMusicId(netId)
            if xSound:soundExists(id) then
                local ent = NetworkGetEntityFromNetworkId(netId)
                if ent and DoesEntityExist(ent) then
                    local p = GetEntityCoords(ent)
                    xSound:Position(id, p)
                end
            end
        end
        Wait(any and ClientCfg.CarryPositionUpdateMs or 500)
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('tk_bb:sv:requestSync')
end)

RegisterCommand('+tk_bb_place', function()
    if LocalCarry.netId then
        TriggerServerEvent('tk_bb:sv:setCarried', LocalCarry.netId, false)
    end
end, false)
RegisterCommand('-tk_bb_place', function() end, false)
RegisterCommand('+tk_bb_store', function()
    if LocalCarry.netId then
        TriggerServerEvent('tk_bb:sv:pickup', LocalCarry.netId)
    end
end, false)
RegisterCommand('-tk_bb_store', function() end, false)