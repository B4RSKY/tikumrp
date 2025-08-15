local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('tk-jobs:duty', function(kantong, duty)
	local xPlayer = QBCore.Functions.GetPlayer(kantong)
	if xPlayer then
		xPlayer.Functions.SetMetaData('disnakerDuty', tostring(duty))
        print(duty)
	end
end)

RegisterNetEvent('tk-disnaker:status')
GuardEventHandler('tk-disnaker:status', function(data)
    local src = source
	local Player = QBCore.Functions.GetPlayer(src)

    --Data Penjahit
	if data.meta.tipe == 'jahit' and data.jenis == 'item' and data.model == 'add' then
        if data.meta.jenis == 'dapat' and data.meta.tipe == 'jahit' then
            if data.meta.dapat == 1 then
                if exports.ox_inventory:CanCarryItem(src, 'wool', data.meta.dapat) then
                    exports.ox_inventory:AddItem(src, 'wool', data.meta.dapat)
                else
                    TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
                end
            end
        elseif data.meta.jenis == 'proses' and data.meta.tipe == 'jahit' then
            if exports.ox_inventory:CanCarryItem(src, 'fabric', data.meta.dapat) then
                exports.ox_inventory:RemoveItem(src, 'wool', data.meta.kurang)
                exports.ox_inventory:AddItem(src, 'fabric', data.meta.dapat)
            else
                TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
            end
        elseif data.meta.jenis == 'kemas' and data.meta.tipe == 'jahit' then
            if exports.ox_inventory:CanCarryItem(src, 'clothe', data.meta.dapat) then
                exports.ox_inventory:RemoveItem(src, 'fabric', data.meta.kurang)
                exports.ox_inventory:AddItem(src, 'clothe', data.meta.dapat)
            else
                TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
            end
        end
    end

    --Data Penambang
    if data.meta.tipe == 'tambang' and data.jenis == 'item' and data.model == 'add' then
        if data.meta.jenis == 'dapat' and data.meta.tipe == 'tambang' then
            if data.meta.dapat == 1 then
                if exports.ox_inventory:CanCarryItem(src, 'stone', data.meta.dapat) then
                    exports.ox_inventory:AddItem(src, 'stone', data.meta.dapat)
                else
                    TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
                    ExecuteCommand('stopmining')
                end
            end
        elseif data.meta.jenis == 'cuci' and data.meta.tipe == 'tambang' then
            if exports.ox_inventory:CanCarryItem(src, 'washed_stone', data.meta.dapat) then
                exports.ox_inventory:RemoveItem(src, 'stone', data.meta.kurang)
                exports.ox_inventory:AddItem(src, 'washed_stone', data.meta.dapat)
            else
                TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
            end
        end
    end

    --Data Ayam
    if data.meta.tipe == 'tayam' and data.jenis == 'item' and data.model == 'add' then
        if data.meta.jenis == 'dapat' and data.meta.tipe == 'tayam' then
            if data.meta.dapat == 1 then
                if exports.ox_inventory:CanCarryItem(src, 'alive_chicken', data.meta.dapat) then
                    exports.ox_inventory:AddItem(src, 'alive_chicken', data.meta.dapat)
                else
                    TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
                end
            end
        elseif data.meta.jenis == 'bunuh' and data.meta.tipe == 'tayam' then
            if exports.ox_inventory:CanCarryItem(src, 'death_chicken', data.meta.dapat) then
                exports.ox_inventory:RemoveItem(src, 'alive_chicken', data.meta.kurang)
                exports.ox_inventory:AddItem(src, 'death_chicken', data.meta.dapat)
            else
                TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
            end
        elseif data.meta.jenis == 'potong' and data.meta.tipe == 'tayam' then
            if exports.ox_inventory:CanCarryItem(src, 'slaughtered_chicken', data.meta.dapat) then
                exports.ox_inventory:RemoveItem(src, 'death_chicken', data.meta.kurang)
                exports.ox_inventory:AddItem(src, 'slaughtered_chicken', data.meta.dapat)
            else
                TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
            end
        elseif data.meta.jenis == 'kemas' and data.meta.tipe == 'tayam' then
            if exports.ox_inventory:CanCarryItem(src, 'packaged_chicken', data.meta.dapat) then
                exports.ox_inventory:RemoveItem(src, 'slaughtered_chicken', data.meta.kurang)
                exports.ox_inventory:AddItem(src, 'packaged_chicken', data.meta.dapat)
            else
                TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
            end
        end
    end

    --Data T.Kayu
    if data.meta.tipe == 'tkayu' and data.jenis == 'item' and data.model == 'add' then
        if data.meta.jenis == 'dapat' and data.meta.tipe == 'tkayu' then
            if exports.ox_inventory:CanCarryItem(src, 'wood', data.meta.dapat) then
                exports.ox_inventory:AddItem(src, 'wood', data.meta.dapat)
            else
                TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
                ExecuteCommand('stoptebang')
            end
        elseif data.meta.jenis == 'proses' and data.meta.tipe == 'tkayu' then
            if exports.ox_inventory:CanCarryItem(src, 'cutted_wood', data.meta.dapat) then
                exports.ox_inventory:RemoveItem(src, 'wood', data.meta.kurang)
                exports.ox_inventory:AddItem(src, 'cutted_wood', data.meta.dapat)
            else
                TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
            end
        elseif data.meta.jenis == 'kemas' and data.meta.tipe == 'tkayu' then
            if exports.ox_inventory:CanCarryItem(src, 'packaged_plank', data.meta.dapat) then
                exports.ox_inventory:RemoveItem(src, 'cutted_wood', data.meta.kurang)
                exports.ox_inventory:AddItem(src, 'packaged_plank', data.meta.dapat)
            else
                TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak bisa membawa lagi', 5000, 'error')
            end
        end
    end

    --Data S.Bus
    if data.meta.tipe == 'sbus' and data.jenis == 'item' and data.model == 'add' then
        if data.meta.jenis == 'cp' and data.meta.tipe == 'sbus' then
            exports.ox_inventory:AddItem(src, 'money', data.meta.dapat)
        elseif data.meta.jenis == 'final' and data.meta.tipe == 'sbus' then
            exports.ox_inventory:AddItem(src, 'money', data.meta.dapat)
        end
    end
end)

--Lebur tambang
local SmeltingConfig = {
    requiredItem = 'washed_stone',
    requiredAmount = 1,
    rewards = {
        {
            chance = 90,
            items = {
                { item = 'copper', amount = math.random(1, 3) }
            }
        },
        {
            chance = 75,
            items = {
                { item = 'copper', amount = math.random(1, 2) },
                { item = 'iron', amount = math.random(1, 2) }
            }
        },
        {
            chance = 50,
            items = {
                { item = 'copper', amount = 1 },
                { item = 'iron', amount = 1 },
                { item = 'gold', amount = math.random(1, 2) }
            }
        },
        {
            chance = 20,
            items = {
                { item = 'copper', amount = 1 },
                { item = 'iron', amount = 1 },
                { item = 'gold', amount = 1 },
                { item = 'diamond', amount = 1 }
            }
        }
    }
}

local function CanCarryItems(source, items)
    for _, itemData in ipairs(items) do
        local canCarry = exports.ox_inventory:CanCarryItem(source, itemData.item, itemData.amount)
        if not canCarry then
            return false, itemData.item
        end
    end
    return true
end

local function GetSmeltingReward()
    local randomValue = math.random(1, 100)

    for i = #SmeltingConfig.rewards, 1, -1 do
        local rewardTier = SmeltingConfig.rewards[i]
        if randomValue <= rewardTier.chance then
            -- Randomize amount untuk setiap item di tier ini
            local finalItems = {}
            for _, item in ipairs(rewardTier.items) do
                table.insert(finalItems, {
                    item = item.item,
                    amount = type(item.amount) == "number" and item.amount or math.random(1, 3)
                })
            end
            return finalItems, i -- Return items dan tier level
        end
    end
    
    -- Fallback ke tier 1 jika ada masalah
    return SmeltingConfig.rewards[1].items, 1
end

RegisterNetEvent('tk-disnaker:mining:lebur', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local hasStone = exports.ox_inventory:GetItemCount(src, SmeltingConfig.requiredItem)
    
    if hasStone < SmeltingConfig.requiredAmount then
        TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Anda tidak memiliki batu yang cukup untuk dilebur!, Minimal '..SmeltingConfig.requiredAmount, 5000, 'error')
        return
    end
    
    local rewardItems, tierLevel = GetSmeltingReward()
    local canCarry, blockedItem = CanCarryItems(src, rewardItems)
    
    if not canCarry then
        TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Inventory Anda penuh! Tidak dapat menampung '..blockedItem, 5000, 'error')
        return
    end
    
    local removed = exports.ox_inventory:RemoveItem(src, SmeltingConfig.requiredItem, SmeltingConfig.requiredAmount)
    
    if not removed then
        TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Gagal mengambil batu dari inventory ', 5000, 'error')
        return
    end
    
    local rewardText = {}
    for _, itemData in ipairs(rewardItems) do
        local added = exports.ox_inventory:AddItem(src, itemData.item, itemData.amount)
        if added then
            table.insert(rewardText, itemData.amount .. 'x ' .. itemData.item)
        end
    end
    
    local tierNames = {'Biasa', 'Bagus', 'Langka', 'Sangat Langka'}
    local tierName = tierNames[tierLevel] or 'Biasa'
    TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', 'Batu berhasil dilebur! (' .. tierName .. ')\nAnda mendapat: ' .. table.concat(rewardText, ', '), 5000, 'error')
    -- Log untuk debugging
    -- print(('[SMELTING] Player %s (%s) smelted stone - Tier: %d, Items: %s'):format(
    --     Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
    --     Player.PlayerData.citizenid,
    --     tierLevel,
    --     table.concat(rewardText, ', ')
    -- ))
end)