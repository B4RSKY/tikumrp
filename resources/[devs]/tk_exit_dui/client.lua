-- CLIENT SIDE
local labels     = {}
local drawThread = nil
local baseTxd    = 'tk_exitdui_txd'
local rtxdHandle = nil

-- ===== Utils =====
local function now() return GetGameTimer() end

local function ensureTxd()
    if not rtxdHandle then
        rtxdHandle = CreateRuntimeTxd(baseTxd)
        print(('[tk_exitdui] RTXD created: %s handle=%s'):format(baseTxd, tostring(rtxdHandle)))
    end
end

local function urlencode(str)
    if not str then return '' end
    str = tostring(str):gsub("\r?\n", " ")
    return str:gsub("([^%w%-%_%.%~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "%%20")
end

local function getClockText()
    return ('%02d:%02d'):format(GetClockHours(), GetClockMinutes())
end

-- Skala sprite yang lebih proporsional
local function getScaleForDistance(world, baseW, baseH)
    local cam = GetGameplayCamCoords()
    local dist = #(world - cam)
    local fov  = GetGameplayCamFov()
    local scale = (1.0 / math.max(dist, 0.01)) * (85.0 / fov) * 1.5 -- Increased scale multiplier
    return baseW * scale, baseH * scale, dist
end

-- ===== DUI compat (ox_lib -> native fallback) =====
local function newDUI(url, width, height, debug)
    -- 1) ox_lib dulu
    if lib and lib.dui and lib.dui.new then
        local o = lib.dui:new({ url = url, width = width, height = height, debug = debug or false })
        local handle
        for _ = 1, 60 do
            handle = o.handle or (o.getHandle and o:getHandle())
            if handle and handle ~= '' then break end
            Wait(0)
        end
        if handle and handle ~= '' then
            return {
                kind   = 'lib',
                obj    = o,
                handle = handle,
                send   = function(self, tbl) if self.obj and self.obj.sendMessage then self.obj:sendMessage(tbl) end end,
                remove = function(self) if self.obj and self.obj.remove then self.obj:remove() end end
            }
        else
            pcall(function() if o and o.remove then o:remove() end end)
        end
    end

    -- 2) Native fallback
    local obj = CreateDui(url, width, height)
    if not obj then return nil end
    local handle
    for _ = 1, 120 do
        handle = GetDuiHandle(obj)
        if handle and handle ~= '' then break end
        Wait(0)
    end
    if not handle or handle == '' then
        DestroyDui(obj)
        return nil
    end
    return {
        kind   = 'native',
        obj    = obj,
        handle = handle,
        send   = function(self, tbl) if self.obj then SendDuiMessage(self.obj, json.encode(tbl)) end end,
        remove = function(self) if self.obj then DestroyDui(self.obj) end end
    }
end

-- Kirim message ke DUI dengan retry
local function sendWithRetry(dui, data, tries, delay)
    tries = tries or 10
    delay = delay or 80
    for _ = 1, tries do
        dui:send({ action = 'render', payload = data })
        Wait(delay)
    end
end

local function setDisplay(dui, visible)
    if not dui then return end
    dui:send({ action = 'display', value = visible and true or false })
end

-- ===== Render loop dengan animasi yang lebih smooth =====
local function startDrawLoop()
    if drawThread then return end
    drawThread = CreateThread(function()
        while true do
            local anyDraw = false
            local t = now()

            for key, lb in pairs(labels) do
                if t >= lb.expire then
                    -- Animasi keluar yang lebih halus
                    if not lb.closing then
                        lb.closing  = true
                        lb.closeAt  = t + 400 -- Extended close animation
                        setDisplay(lb.dui, false)
                    elseif t >= (lb.closeAt or t) then
                        if lb.dui then lb.dui:remove() end
                        labels[key] = nil
                    end
                else
                    local tw, th, dist = getScaleForDistance(lb.coords, lb.w, lb.h)
                    tw = tw * (lb.scale or 1.0)
                    th = th * (lb.scale or 1.0)

                    -- Lerp yang lebih responsif untuk animasi scale
                    local lerpSpeed = 0.15 -- Faster lerp for smoother animation
                    lb._w = lb._w and (lb._w + (tw - lb._w) * lerpSpeed) or tw
                    lb._h = lb._h and (lb._h + (th - lb._h) * lerpSpeed) or th

                    -- Fade in animation untuk label baru
                    if not lb.fadeStarted then
                        lb.fadeStarted = true
                        lb.fadeStart = t
                        lb.alpha = 0
                    end

                    -- Calculate fade alpha
                    local fadeTime = 600 -- 600ms fade in
                    if lb.fadeStart and t < lb.fadeStart + fadeTime then
                        lb.alpha = math.min(255, (t - lb.fadeStart) / fadeTime * 255)
                    else
                        lb.alpha = 255
                    end

                    if dist <= (lb.maxDrawDist or 50.0) then
                        SetDrawOrigin(lb.coords.x, lb.coords.y, lb.coords.z + 1.0, 0) -- Slightly lower
                        DrawSprite(lb.txd, lb.txn, 0.0, 0.0, lb._w, lb._h, 0.0, 255, 255, 255, math.floor(lb.alpha or 255))
                        ClearDrawOrigin()
                        anyDraw = true
                    end
                end
            end

            if next(labels) == nil then
                drawThread = nil
                return
            end

            if anyDraw then Wait(0) else Wait(150) end
        end
    end)
end

-- ===== Spawn 1 label (ukuran lebih kecil) =====
local function createExitLabel(payload)
    ensureTxd()

    local id         = payload.id
    local coords     = payload.coords
    local identifier = payload.identifier
    local reason     = payload.reason
    local duration   = tonumber(payload.duration) or 25000 -- Slightly shorter default
    local maxDraw    = tonumber(payload.maxDrawDist) or 50.0 -- Reduced draw distance
    local timeText   = payload.timeText or getClockText()
    local titleText  = payload.title or ('ID %s'):format(id)
    local subText    = identifier
    local reasonText = tostring(reason or 'Unknown')
    local fontScale  = payload.fontScale or 1.1 -- Increased default font scale

    local url = ('nui://%s/web/index.html?time=%s&title=%s&sub=%s&rt=%s&reason=%s&fs=%s&ts=%d')
        :format(GetCurrentResourceName(),
            urlencode(timeText),
            urlencode(titleText),
            urlencode(subText),
            urlencode('DISCONNECT'),
            urlencode(reasonText),
            urlencode(fontScale),
            math.random(100000, 999999)
        )

    -- Ukuran DUI yang lebih besar: 1600x800 (ratio 2:1)
    local dui = newDUI(url, 1600, 800, false)
    if not dui or not dui.handle then
        print('^1[tk_exit_dui]^0 gagal membuat DUI (lib & native).')
        return
    end

    sendWithRetry(dui, {
        header = 'DISCONNECTED',
        time = timeText,
        title = titleText,
        subtitle = subText,
        reasonTitle = 'DISCONNECT REASON',
        reason = reasonText,
        fontScale = fontScale
    }, 12, 80)

    local txn = ('label_%s_%d'):format(id or '0', now() % 100000)
    CreateRuntimeTextureFromDuiHandle(rtxdHandle, txn, dui.handle)

    labels[txn] = {
        dui = dui, txd = baseTxd, txn = txn,
        coords = vector3(coords.x, coords.y, coords.z),
        expire = now() + duration,
        w = 0.28, h = 0.14,         -- Larger dimensions (ratio 2:1)
        maxDrawDist = maxDraw,
        scale = payload.scale or 1.5 -- Increased scale
    }

    setDisplay(dui, true)
    startDrawLoop()
end

-- ===== Net event =====
RegisterNetEvent('tk:res:cl:exit:spawnLabel', function(payload)
    if type(payload) ~= 'table' or not payload.coords then return end
    local me = PlayerPedId()
    if #(GetEntityCoords(me) - payload.coords) > (payload.maxDrawDist or 50.0) + 15.0 then return end
    createExitLabel(payload)
end)

-- ===== DEBUG =====
RegisterCommand('exitdui', function(_, args)
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    local f = GetEntityForwardVector(ped)
    local coords = vector3(p.x + f.x * 2.0, p.y + f.y * 2.0, p.z)

    TriggerEvent('tk:res:cl:exit:spawnLabel', {
        id = GetPlayerServerId(PlayerId()),
        coords = coords,
        identifier = 'steam:110000xxxxxxx',
        reason = 'Connection timeout - Server did not respond',
        duration = tonumber(args[1]) or 20000,
        maxDrawDist = 20.0,
        timeText = getClockText(),
        title = 'B4RSKY GACOR',
        scale = tonumber(args[2]) or 3.5,
        fontScale = tonumber(args[3]) or 1.5
    })
end, false)

RegisterCommand('tk_exitdui_clear', function()
    local n = 0
    for k, lb in pairs(labels) do
        if lb.dui then lb.dui:remove() end
        labels[k] = nil
        n = n + 1
    end
    print(('[tk_exit_dui] cleared %d labels'):format(n))
end, false)