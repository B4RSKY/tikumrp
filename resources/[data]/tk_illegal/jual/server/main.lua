local QBCore = exports['qb-core']:GetCoreObject()
local cfg = ServerConfig

local lastSellAt = {}
local zoneHeat = {} 

local function isAllowedGang(src)
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer or not xPlayer.PlayerData or not xPlayer.PlayerData.gang then return false end
    local gname = string.lower(xPlayer.PlayerData.gang.name or '')
    for _, g in ipairs(cfg.AllowedGangs) do
        if gname == string.lower(g) then return true end
    end
    return false
end

local function getZone(zoneId)
    for _, z in ipairs(cfg.Zones) do if z.id == zoneId then return z end end
end

local function inSet(setTbl, key)
    for _, v in ipairs(setTbl) do if v == key then return true end end
    return false
end

local function randomBasePrice(itemCfg)
    local mn, mx = itemCfg.priceMin or 0, itemCfg.priceMax or 0
    if mx <= mn then return math.floor(mn) end
    return math.floor(mn + (mx - mn) * math.random() + 0.5)
end

local function updateHeat(zoneId, add)
    local st = zoneHeat[zoneId]
    local now = os.time()
    if not st then
        st = { value = 0.0, updated = now }
    else
        local minutes = math.max(0, now - (st.updated or now)) / 60.0
        local dec = (cfg.Heat.decayPerMinute or 0.0) * minutes
        st.value = math.max(0.0, (st.value or 0.0) - dec)
        st.updated = now
    end
    if add and add ~= 0 then
        st.value = (st.value or 0.0) + add
        st.updated = now
    end
    zoneHeat[zoneId] = st
    return st.value
end

-- Kalkulasi harga dinamis (jam server + heat)
local function calcDynamicUnitPrice(itemCfg, zoneId)
    local unit = randomBasePrice(itemCfg)
    local mult = 1.0

    -- Jam server
    local hour = tonumber(os.date('%H'))
    if inSet(cfg.Pricing.nightHours or {}, hour) then
        mult = mult * (1.0 + (cfg.Pricing.nightBonus or 0.0))
    elseif inSet(cfg.Pricing.middayHours or {}, hour) then
        mult = mult * (1.0 - (cfg.Pricing.middayPenalty or 0.0))
    end

    -- Heat discount
    local heat = updateHeat(zoneId, 0) -- cuma ambil nilai terkini
    local disc = math.min((cfg.Heat.maxPriceDiscount or 0.0), heat * (cfg.Heat.priceDiscountPerHeat or 0.0))
    mult = mult * (1.0 - disc)

    unit = math.max(1, math.floor(unit * mult + 0.5))
    return unit, heat, { hour = hour, mult = mult, disc = disc }
end

local function calcDispatchChance(zoneId, heat, baseOverride)
    local z = getZone(zoneId)
    local base = baseOverride or (z and z.dispatch and z.dispatch.baseChance) or (cfg.Dispatch.baseChance or 0)
    local chance = base + (heat * (cfg.Heat.dispatchChancePerHeat or 0.0))

    local hour = tonumber(os.date('%H'))
    if inSet(cfg.Pricing.nightHours or {}, hour) then
        -- malam lebih aman
        chance = chance * (cfg.Dispatch.nightFactor or 1.0)
    end
    chance = math.max(0, math.min(100, chance))
    return chance
end

lib.callback.register('tk-illegal:jual', function(source, zoneId, itemName, amount)
    local src = source
    if type(zoneId) ~= 'string' or type(itemName) ~= 'string' or type(amount) ~= 'number' then
        return false, 'Argumen tidak valid'
    end

    local nowClock = os.clock()
    if (nowClock - (lastSellAt[src] or 0)) < (cfg.TransactionCooldown or 2.0) then
        return false, 'Terlalu cepat, coba lagi'
    end

    if not isAllowedGang(src) then
        return false, 'Gang tidak diizinkan'
    end

    local z = getZone(zoneId)
    if not z then return false, 'Zona tidak dikenal' end

    local expectedItem = z.sellItem
    if expectedItem and expectedItem ~= itemName then
        return false, 'Item tidak diterima di zona ini'
    end

    local itemCfg = cfg.Items[itemName]
    if not itemCfg then return false, 'Item tidak terdaftar' end

    amount = math.floor(amount)
    local required = math.max(1, cfg.RequiredAmount or 1)
    if amount < required then
        return false, ('Minimal %d'):format(required)
    end

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return false, 'Player tidak ditemukan' end

    local maxTx = itemCfg.maxPerTransaction or amount
    if amount > maxTx then amount = maxTx end

    local have = exports.ox_inventory:GetItemCount(src, itemName)
    if (have or 0) < amount then
        return false, ('Kamu hanya punya %d'):format(have or 0)
    end

    -- Kalkulasi harga dinamis + update heat (+1 sale)
    local unitBase, heatBefore = 0, 0
    unitBase, heatBefore = calcDynamicUnitPrice(itemCfg, zoneId)
    local unitPrice = unitBase
    -- Tambah heat karena transaksi ini
    local heatAfter = updateHeat(zoneId, (cfg.Heat.increasePerSale or 0.0))

    if not exports.ox_inventory:RemoveItem(src, itemName, amount) then
        return false, 'Gagal menghapus item'
    end

    local payout = math.max(0, unitPrice * amount)
    
    if not exports.ox_inventory:AddItem(src, 'black_money', payout) then
        exports.ox_inventory:AddItem(src, itemName, amount)
        return false, 'Gagal membayar'
    end

    lastSellAt[src] = nowClock

    local rolledDispatch = false
    if cfg.Dispatch and cfg.Dispatch.enabled then
        local chance = calcDispatchChance(zoneId, heatAfter, z.dispatch and z.dispatch.baseChance)
        if math.random(1, 100) <= math.floor(chance) then
            rolledDispatch = true
            TriggerClientEvent('tk-illegal:jual:call', src, { type = 'drug_sale', zone = z.label or z.id })
        end
    end

    local name = GetPlayerName(src) or ('ID '..tostring(src))
    local desc = ("**Player:** %s (%d)\n**Zone:** %s\n**Item:** %s x%d\n**Harga per unit:** TK$%d\n**Payout:** TK$%d\n**Heat:** %.1f ➜ %.1f\n**Dispatch:** %s")
        :format(name, src, z.label or z.id, itemCfg.label or itemName, amount, unitPrice, payout, heatBefore, heatAfter, rolledDispatch and "YES" or "NO")
    TriggerEvent('qb-log:server:CreateLog', 'drug_sale', 'Jual Drugs', 'ungu', desc, false)

    return true, { amount = amount, paid = payout, itemLabel = (itemCfg.label or itemName), unitPrice = unitPrice }
end)

AddEventHandler('playerDropped', function()
    lastSellAt[source] = nil
end)
