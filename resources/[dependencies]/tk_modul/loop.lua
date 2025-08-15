loops = {} -- untuk cache data semua loops.
intervals = {}
allCache = {}

loop = { -- kumpulan functions dari loop.
    ---membuat loop
    ---@param id string id yang akan dipanggil/hapus/edit dll.
    ---@param fungsi any function yang mau dibuatkan loop.
    ---@param tick number? jumlah tick yang mau diproses pada setiap jeda loop.
    create = function(id, fungsi, tick)
        if loops[id] and debug then print('id loop '..id..' sudah ada sebelumnya') end
        loops[id] = {
            status = false,
            func = fungsi,
            tick = tick,
            meta = {},
        }
    end,
    ---membuat loop jika belum terbuat
    ---@param id string
    ---@param fungsi any
    ---@param tick any
    createIfNotExist = function(id, fungsi, tick)
        if loops[id] then return end
        loops[id] = {
            status = false,
            func = fungsi,
            tick = tick,
            meta = {},
        }
    end,
    ---menimpa loop yang sudah terbuat
    ---@param id string
    ---@param fungsi any
    ---@param tick any
    createReplaceExist = function(id, fungsi, tick)
        if loops[id] then loops[id] = {} end
        loops[id] = {
            status = false,
            func = fungsi,
            tick = tick,
            meta = {},
        }
    end,
    ---membuang loop
    ---@param id string
    remove = function(id)
        if not loops[id] then return end
        if loops[id].status then loop.stop(id) end
        loops[id] = nil
    end,
    ---mendapatkan data loop
    ---@param id string
    ---@return table
    get = function(id)
        if not loops[id] then return end
        return loops[id]
    end,
    ---mengubah data loop
    ---@param id string
    ---@param key string
    ---@param value any
    edit = function(id, key, value)
        if not loops[id] or not loops[id][key] then return end
        local nyala = false
        if loops[id].status then
            nyala = true
            loop.stop(id)
        end
        loops[id][key] = value
        if nyala then
            loop.start(id)
        end
    end,
    ---menjalankan loop yang sudah terbuat
    ---@param id string
    ---@param meta table? metadata yang ingin dikirimkan kedalam loop dan bisa diproses didalam loop.
    start = function(id, meta)
        if not loops[id] then return end
        if loops[id].status then return end
        if meta then loops[id].meta = meta end
        loops[id].status = true
        CreateThread(function()
            while loops[id] and loops[id].status do
                loops[id].func(loops[id].meta and loops[id].meta or nil)
                Wait(loops[id].tick or 1)
            end
        end)
    end,
    startFirst = function(id, meta)
        if not loops[id] then return end
        if loops[id].status then return end
        if meta then loops[id].meta = meta end
        loops[id].status = true
        CreateThread(function()
            while loops[id] and loops[id].status do
                Wait(loops[id].tick or 1)
                loops[id].func(loops[id].meta and loops[id].meta or nil)
            end
        end)
    end,
    stop = function(id, removemeta)
        if not loops[id] then return end
        if not loops[id].status then return end
        loops[id].status = false
        if removemeta then loops[id].meta = {} end
    end,
    state = function(id)
        if not loops[id] then return end
        return loops[id].status
    end,
    toggle = function(id, fungsi)
        if not loops[id] then return end
        if loops[id].status then
            loop.stop(id)
            if fungsi then
                fungsi(loops[id].status)
            end
        else
            loop.start(id)
            if fungsi then
                fungsi(loops[id].status)
            end
        end
    end,
    setmeta = function(id, key, value)
        if not loops[id] then return end
        if not loops[id].meta then loops[id].meta = {} end
        loops[id].meta[key] = value
        return loops[id].meta[key]
    end,
    getmeta = function(id, key)
        if not loops[id] then return end
        if not loops[id].meta then return end
        if not loops[id].meta[key] then return end
        return loops[id].meta[key]
    end,
    getallmeta = function(id)
        if not loops[id] then return end
        if not loops[id].meta then return end
        return loops[id].meta
    end,
    bool = function(id, bool, meta)
        if not loops[id] then return end
        if bool then
            loop.start(id, meta)
        else
            loop.stop(id, meta)
        end
    end,
    onStopped = function(id, func)
        if not loops[id] then return end
        if not func then return end
        loops[id].onStopped = func
    end,
    stopUntil = function(id, tick)
        if not loops[id] then return end
        if not tick then return end
        loops[id].stopUntil = tick
        loops[id].tickCount = 0
        -- print(loops[id].stopUntil, loops[id].tickCount)
    end,
    startFrom = function(id, eventName, meta, first)
        if not loops[id] then return end
        if not eventName then return end
        AddEventHandler(eventName, function()
            if first then
                loop.startFirst(id,meta)
            else
                loop.start(id,meta)
            end
        end)
    end,
    stopWhen = function(id, eventName, removemeta)
        if not loops[id] then return end
        if not eventName then return end
        AddEventHandler(eventName, function()
            loop.stop(id, removemeta)
        end)
    end,
    advanced = function(adv)
        if not adv.name then return end
        loop.create(adv.name, adv.loop, adv.tick or 0)
        if adv.start then
            loop.startFrom(adv.name, adv.start, adv.meta or {}, adv.first or false)
        end
        if adv.stop then
            loop.stopWhen(adv.name, adv.stop, adv.removemeta or false)
        end
        if adv.ketika then
            loop.ketika(adv.name, adv.ketika, adv.meta)
        end
        if adv.max then
            loop.stopUntil(adv.name, adv.max)
        end
        if adv.onStopped then
            loop.onStopped = function(meta)
                adv.onStopped(meta)
            end
        end
    end,
    nilHandler = function(tipe, var, checkLoop, stopped)
        local randomNameLoop = randomString(11)
        if tipe == 'state' then
            loop.create(randomNameLoop, function()
                if LocalPlayer.state[var] == nil then
                    checkLoop(randomNameLoop)
                else
                    stopped()
                    loop.stop(randomNameLoop)
                end
            end, 100)
        elseif tipe == 'variable' then
            local namareso = GetCurrentResourceName()
            exports(randomNameLoop, function()
                return loopTemp[var]
            end)
            loop.create(randomNameLoop, function()
                local getVar = exports[namareso][randomNameLoop]()
                if getVar == nil then
                    checkLoop(randomNameLoop)
                else
                    stopped()
                    loop.stop(randomNameLoop)
                end
            end, 100)
        end
        loop.start(randomNameLoop)
        return randomNameLoop
    end,
    ketika = function(tipe, id, var, meta, tick)
        if not loops[id] then return end
        local randomNameLoop = randomString(11)
        loop.create(randomNameLoop, function()
            if tipe == 'state' then
                if LocalPlayer.state[var] then
                    if not loop.state(id) then
                        loop.start(id, meta or {})
                    end
                else
                    if loop.state(id) then
                        loop.stop(id)
                    end
                end
            else
                if loopTemp[var] then
                    if not loop.state(id) then
                        loop.start(id, meta or {})
                    end
                else
                    if loop.state(id) then
                        loop.stop(id)
                    end
                end
            end
        end, tick or 100)
        loop.start(randomNameLoop)
        return randomNameLoop
    end,
    -- interval = function(id, func, tick)
    --     loop.create(id, func, tick)
    --     loop.startFirst(id)
    --     return true
    -- end
    interval = function(id, cb, int, ...)
        int = int or 0

        if type(int) ~= 'number' then
            return error(('Interval must be a number. Received %s'):format(json.encode(int --[[@as unknown]])))
        end

        local cbType = type(cb)

        if cbType == 'number' and intervals[cb] then
            intervals[cb] = int or 0
            return
        end

        -- if cbType ~= 'function' then
        --     return error(('Callback must be a function. Received %s'):format(cbType))
        -- end

        local args = { ... }

        Citizen.CreateThreadNow(function(ref)
            -- id_new = ref
            intervals[id] = int or 0
            -- intervals[id_new] = int or 0
            repeat
                int = intervals[id]
                Wait(int)
                cb(table.unpack(args))
            until int < 0
            intervals[id] = nil
        end)
        return id
        -- return id_new
    end,
    removeInterval = function (id)
        if not intervals[id] then
            return error(('No interval exists with id %s'):format(id))
        end
    
        intervals[id] = -1
    end,
    ---onCache: integrasi dengan ox_lib lib.onCache, menjalakan ketika cache memiliki value.
    ---@param key string/nama cache yang terdaftar di ox_lib cache systems
    ---@param funcdata any/loopname yang sudah di create sebelumnya, bisa single string atau multiple string menggunakan table array
    ---@param data table/metadata, jika satu loopname saja cukup langsung dalam bentuk table array, apabila menggunakan multiple loopname dapat menggunakan table tipe hash dengan key sesuai dengan loopname.
    ---@return any/integer jika satu loopname, table jika multiple loopname
    onCache = function (key, funcdata, data)
        if not allCache[key] then allCache[key] = {} end
        if type(funcdata) == 'string' then
            local id = #allCache[key]+1
            allCache[key][id] = function (value)
                if not data then data = {} end
                if value then
                    data.cache = value
                    loop.start(funcdata, data)
                else
                    loop.stop(funcdata)
                end
            end
            addToCache(key, id)
            return id
        elseif type(funcdata) == 'table' then
            local ids = {}
            for i=1, #funcdata do
                local id = #allCache[key]+1
                allCache[key][id] = function (value)
                    if not data then data = {} end
                    if not data[funcdata[i]] then data[funcdata[i]] = {} end
                    if value then
                        data[funcdata[i]].cache = value
                        loop.start(funcdata[i], data[funcdata[i]])
                    else
                        loop.stop(funcdata[i])
                    end
                end
                addToCache(key, id)
                ids[funcdata[i]] = id
            end
            return ids
        end
    end
}

function addToCache(key, id)
    AddEventHandler(('ox_lib:cache:%s'):format(key), function (value)
        allCache[key][id](value)
    end)
end

local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

function randomString(length)
    if not length or length <= 0 then return '' end
    math.random(5)
    return randomString(length - 1) .. charset[math.random(1, #charset)]
end

function getLoop()
    return loop
end

function getLoops(id)
    return id and loops[id] or loops
end

exports('getLoop', getLoop)
exports('getLoops', getLoops)

-- https://docs.fivem.id/fmid_loop