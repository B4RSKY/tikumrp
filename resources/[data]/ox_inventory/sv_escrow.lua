--[[
  Inventory Server Module (refactored)
  - Framework detection (ESX/QBCore/QBX) and unified helpers
  - Backpack utilities (capacity lookup, stash registration, item checks)
  - Theme management (callbacks/events/command)
  - Armor plate logic (insert/remove/sync/persist)
  - Item drop hook for custom world drops
  - All FiveM natives and external calls preserved
]]

-- Public API table (kept name for compatibility with existing code)
ServerFuncs = {}

-- Framework handles
local ESX = nil            -- ESX shared object
local QBCore = nil         -- QBCore object
local QBX = nil            -- qbx_core exports proxy
local FrameworkResource = nil
local FrameworkKey = nil   -- "esx" | "qb" | "qbx"

-- Detect framework and perform initial registrations
CreateThread(function()
  Wait(5000)

  local state = GetResourceState("qbx_core")
  if state == "started" then
    FrameworkResource = "qbx_core"
    QBX = exports.qbx_core
    FrameworkKey = "qbx"
  else
    state = GetResourceState("qb-core")
    if state == "started" then
      FrameworkResource = "qb_core"
      QBCore = exports["qb-core"]:GetCoreObject()
      FrameworkKey = "qb"
    else
      state = GetResourceState("es_extended")
      if state == "started" then
        FrameworkResource = "es_extended"
        ESX = exports.es_extended:getSharedObject()
        FrameworkKey = "esx"
      end
    end
  end

  GlobalState.fw = FrameworkKey

  -- Shared backpack stash (used when backpacks are not owner-bound)
  if not Config.Backpack.owner then
    exports.ox_inventory:RegisterStash(
      "backpack",
      "Backpack",
      Config.Backpack.slots,
      Config.Backpack.maxWeight,
      true
    )
  end
end)

-- Get framework player object by source
local function GetPlayerBySource(src)
  if FrameworkKey == "esx" then
    return ESX.GetPlayerFromId(src)
  elseif FrameworkKey == "qb" then
    return QBCore.Functions.GetPlayer(src)
  elseif FrameworkKey == "qbx" then
    return QBX:GetPlayer(src)
  end
end

-- Return unique player identifier (ESX license or QBCore/QBX citizenid)
function ServerFuncs.getIdentifier(src)
  local ply = GetPlayerBySource(src)
  local ident
  if ply then
    if ply.getIdentifier then
      ident = ply.getIdentifier()
      if ident then
        return ident
      end
    end
    ident = ply.PlayerData.citizenid
  end
  return ident
end

-- Get bank balance for a player
function ServerFuncs.GetBankBal(src)
  local ply = GetPlayerBySource(src)
  if not ply then
    return 0
  end

  if FrameworkKey == "esx" then
    return ply.getAccount("bank").money
  end

  return ply.PlayerData.money.bank
end

-- Remove money from player bank with optional reason (framework-aware)
function ServerFuncs.RemoveMoney(src, amount, reason)
  local ply = GetPlayerBySource(src)
  if not ply then
    return false
  end

  if FrameworkKey == "esx" then
    return ply.removeAccountMoney("bank", amount)
  end

  return ply.Functions.RemoveMoney("bank", amount, reason)
end

-- Get backpack capacity (slots & maxWeight) for an item name
local function GetBackpackCapacity(itemName)
  local def = exports.ox_inventory:Items(itemName)
  if not def then
    return Config.Backpack.slots, Config.Backpack.maxWeight
  end

  local slots = def.bp_slot or Config.Backpack.slots
  local weight = (def.bp_weight or Config.Backpack.maxWeight) * 1000 -- convert to grams
  return slots, weight
end

-- Check if an item qualifies as a backpack/utility/backpack-eligible item
local function IsBackpackEligibleItem(itemName)
  if not itemName then
    return false
  end

  local def = exports.ox_inventory:Items(itemName)
  if def and def.backpack == true then
    return true
  end

  local utilList = (Config.UtilitySlots[1] or {})
  for _, name in ipairs(utilList) do
    if itemName == name then
      return true
    end
  end

  for _, name in ipairs(Config.BackpackBlacklist) do
    if itemName == name then
      return true
    end
  end

  return false
end

-- Register a per-owner backpack stash with capacity derived from item definition
local function RegisterBackpackStash(stashId, itemName)
  local slots, weight = GetBackpackCapacity(itemName)
  exports.ox_inventory:RegisterStash(stashId, "Backpack", slots, weight, false)
end

-- Return slot-1 item if it is backpack-eligible; otherwise nil
local function GetFirstSlotBackpackItem(src)
  local slot = exports.ox_inventory:GetSlot(src, 1)
  if slot then
    if IsBackpackEligibleItem(slot.name) then
      return slot
    end
  end
  return nil
end

-- Callback: return backpack info for UI (hasBackpack, capacity, id, itemName)
lib.callback.register("akilla-inventory:GetBackpackItem", function(_, src)
  local plyState = Player(src).state
  local bpState = plyState.backpack
  if bpState == nil then
    return false
  end

  local inv = Inventory(src)
  if not (inv and inv.items) then
    return false
  end

  local first = inv.items[1]
  if not (first and IsBackpackEligibleItem(first.name)) then
    return false
  end

  local slots, weight = GetBackpackCapacity(first.name)
  return {
    hasBackpack = true,
    slots = slots,
    maxWeight = weight,
    id = bpState.id,
    itemName = first.name
  }
end)

-- Build current theme payload from config
local function GetCurrentTheme()
  local current = Config.Themes.current or "default"
  local theme = Config.Themes.themes[current]
  if not theme then
    print(("^3[WARNING]^7 Theme '%s' not found, falling back to default theme"):format(current))
    theme = Config.Themes.themes.default
  end

  return {
    name = current,
    displayName = theme.name,
    colors = theme.colors
  }
end

-- Callback: get active inventory theme
lib.callback.register("akilla-inventory:getTheme", function(_)
  return GetCurrentTheme()
end)

-- Event: change theme (broadcast to everyone)
RegisterNetEvent("akilla-inventory:changeTheme", function(themeKey)
  local src = source
  local exists = Config.Themes.themes[themeKey]
  if exists then
    Config.Themes.current = themeKey
    local payload = GetCurrentTheme()
    TriggerClientEvent("akilla-inventory:themeChanged", -1, payload)
    print("^2[INFO]^7 Theme changed to: " .. themeKey .. " by player " .. src)
  else
    TriggerClientEvent("ox_lib:notify", src, {
      type = "error",
      description = "Invalid theme name: " .. tostring(themeKey)
    })
  end
end)

-- Callback: ESX license (kept exact logic)
lib.callback.register("akilla-inventory:ESX:GetLicense", function(src)
  local ply = GetPlayerBySource(src)
  if ply then
    ply = ply.getIdentifier
  end
  return ply()
end)

-- Callback: unified identifier via ServerFuncs
lib.callback.register("sk-inv:getIdent", function(src)
  return ServerFuncs.getIdentifier(src)
end)

-- Event: remove parachute item
RegisterNetEvent("akilla-inventory:RemoveParachute", function()
  exports.ox_inventory:RemoveItem(source, "parachute", 1)
end)

-- Event: update armor metadata value at a specific slot
RegisterNetEvent("akilla-inventory:UpdateArmor", function(value, slotIndex)
  local src = source
  local slot = exports.ox_inventory:GetSlot(src, slotIndex)
  if slot then
    slot.metadata.value = value
    exports.ox_inventory:SetMetadata(src, slot.slot, slot.metadata)
  end
end)

-- Event: sync applied backpack clothes and (optionally) register per-owner stash
RegisterNetEvent("akilla-inventory:SyncBackpackClothes", function(outfitId)
  local src = source
  TriggerClientEvent("akilla-inventory:SetBackpackClothes", -1, src, outfitId)

  if outfitId and Config.Backpack.owner then
    local slot = GetFirstSlotBackpackItem(src)
    if slot then
      local stashId = "backpack-" .. outfitId
      RegisterBackpackStash(stashId, slot.name)
    end
  end
end)

-- Event: reply with identifier for armor systems
RegisterServerEvent("akilla-inventory:Armor:GetIdentifier", function()
  local src = source
  local a, b = ServerFuncs.getIdentifier(src)
  TriggerClientEvent("akilla-inventory:Armor:RecieveIdentifier", src, a, b)
end)

-- Event: when an item is equipped (slot==1 -> backpack), register stash if needed
AddEventHandler("ox_inventory:itemEquipped", function(src, item, slotIndex)
  if slotIndex == 1 then
    if IsBackpackEligibleItem(item.name) and Config.Backpack.owner then
      local st = Player(src).state
      local bp = st.backpack
      if bp then
        local stashId = "backpack-" .. bp.id
        RegisterBackpackStash(stashId, item.name)
      end
    end
  end
end)

-- Armor math helpers
local function CalcArmorFromPlates(plates)
  return math.min(plates * Config.ArmorPlates.ArmorPerPlate, 100)
end

local function CalculatePlateCountFromArmor(armor)
  if armor >= 100 then
    return 5
  elseif armor > 80 then
    return 4
  elseif armor > 60 then
    return 3
  elseif armor > 40 then
    return 2
  elseif armor > 20 then
    return 1
  else
    return 0
  end
end

-- Local cache (not read anywhere else, kept for logic parity)
local CurrentPlateCount = 0

-- Event: insert a single armor plate into the vest (slot 2)
RegisterNetEvent("armor:insertPlate", function()
  local src = source

  local vest = exports.ox_inventory:GetSlot(src, 2)
  if not vest then
    return TriggerClientEvent("ox_lib:notify", src, { type = "error", description = "No Vest In Armor Slot" })
  end

  local plates = vest.metadata.plates or 0
  if plates >= Config.ArmorPlates.MaxPlates then
    return TriggerClientEvent("ox_lib:notify", src, { type = "error", description = "Vest is full" })
  end

  local removed = exports.ox_inventory:RemoveItem(src, Config.ArmorPlates.PlateItem, 1)
  if removed then
    plates = plates + 1
    CurrentPlateCount = plates

    exports.ox_inventory:SetMetadata(src, vest.slot, {
      plates = plates,
      rarity = vest.metadata.rarity
    })

    local id = ServerFuncs.getIdentifier(src)
    GlobalState["aki-inv-" .. id] = { plates = plates, hasPlates = true }
    SetResourceKvp(
      "akilla-inventory-armor-plates-" .. id,
      json.encode(GlobalState["aki-inv-" .. id])
    )

    SetPedArmour(GetPlayerPed(src), CalcArmorFromPlates(plates))
    TriggerClientEvent("armor:syncArmor", src)
    TriggerClientEvent("ox_lib:notify", src, { type = "success", description = "Plate inserted." })
  else
    TriggerClientEvent("ox_lib:notify", src, { type = "error", description = "No armor plates!" })
  end
end)

-- Event: remove all plates from vest and return them as items
RegisterNetEvent("armor:removePlates", function()
  local src = source

  local vest = exports.ox_inventory:GetSlot(src, 2)
  if not vest then
    return
  end

  local armor = GetPedArmour(GetPlayerPed(src))
  local count = math.floor(armor / Config.ArmorPlates.ArmorPerPlate)
  if count <= 0 then
    return
  end

  exports.ox_inventory:AddItem(src, Config.ArmorPlates.PlateItem, count)
  exports.ox_inventory:SetMetadata(src, vest.slot, {
    plates = 0,
    rarity = vest.metadata.rarity
  })

  local id = ServerFuncs.getIdentifier(src)
  DeleteResourceKvp("akilla-inventory-armor-plates-" .. id)
  GlobalState["aki-inv-" .. id] = {}

  CurrentPlateCount = 0
  SetPedArmour(GetPlayerPed(src), 0)

  TriggerClientEvent("armor:syncArmor", src)
  TriggerClientEvent("ox_lib:notify", src, { type = "success", description = ("Removed %s plates."):format(count) })
end)

-- Event: sync vest metadata plates if armor-derived plate count changed
RegisterNetEvent("armor:maybeRemovePlate", function(currentArmor)
  local src = source
  local id = ServerFuncs.getIdentifier(src)
  if not id then
    return
  end

  local slotIndex = 2
  local vest = exports.ox_inventory:GetSlot(src, slotIndex)
  if not (vest and vest.metadata.plates) then
    return
  end

  local wanted = CalculatePlateCountFromArmor(currentArmor)
  if wanted ~= vest.metadata.plates then
    GlobalState["aki-inv-" .. id] = GlobalState["aki-inv-" .. id] or {}
    GlobalState["aki-inv-" .. id].plates = wanted

    SetResourceKvp(
      "akilla-inventory-armor-plates-" .. id,
      json.encode(GlobalState["aki-inv-" .. id])
    )

    exports.ox_inventory:SetMetadata(src, vest.slot, {
      plates = wanted,
      rarity = vest.metadata.rarity
    })
  end
end)

-- Event: reapply armor value (on respawn/relog, etc.)
RegisterServerEvent("akilla-inventory:Server:ReApplyPlates", function()
  local src = source
  Wait(250)

  local vest = exports.ox_inventory:GetSlot(src, 2)
  if vest then
    local armor = CalcArmorFromPlates(vest.metadata.plates or 0)
    TriggerClientEvent("akilla-inventory:setArmor", src, armor)
  end
end)

-- Admin command: change inventory theme
lib.addCommand("setinvtheme", {
  help = "Change the inventory theme",
  params = {
    { name = "theme", type = "string", help = "Theme name (default, dark, blue, purple, red, green, custom)" }
  },
  restricted = "group.admin"
}, function(src, args)
  local key = args.theme
  local found = Config.Themes.themes[key]
  if found then
    Config.Themes.current = key
    local payload = GetCurrentTheme()
    TriggerClientEvent("akilla-inventory:themeChanged", -1, payload)
    TriggerClientEvent("ox_lib:notify", src, {
      type = "success",
      description = "Theme changed to: " .. Config.Themes.themes[key].name
    })
  else
    TriggerClientEvent("ox_lib:notify", src, {
      type = "error",
      description = "Available themes: " .. table.concat(table.keys(Config.Themes.themes), ", ")
    })
  end
end)

-- On player drop: refund plates back to items and reset vest metadata
AddEventHandler("playerDropped", function()
  local src = source
  local vest = exports.ox_inventory:GetSlot(src, 2)
  if vest then
    local plates = vest.metadata.plates
    if plates then
      exports.ox_inventory:AddItem(src, Config.ArmorPlates.PlateItem, plates)
      exports.ox_inventory:SetMetadata(src, vest.slot, {
        plates = 0,
        rarity = vest.metadata.rarity
      })
    end
  end
end)

-- Custom drop model mapping
local ItemDropModels = Config.ItemDrops
local DefaultDropModel = Config.DefaultDropModel

-- Hook: convert "newdrop" swap into a persistent custom world drop
exports.ox_inventory:registerHook("swapItems", function(payload)
  if payload.toInventory ~= "newdrop" then
    return
  end

  local fromSlot = payload.fromSlot

  -- Build item list for the drop
  local dropItems = {
    { fromSlot.name, payload.count, fromSlot.metadata }
  }

  local model = ItemDropModels[fromSlot.name] or DefaultDropModel

  local dropId = exports.ox_inventory:CustomDrop(
    fromSlot.label,
    dropItems,
    GetEntityCoords(GetPlayerPed(payload.source)),
    50,           -- radius
    99999999,     -- lifetime
    nil,          -- owner
    model
  )

  if not dropId then
    print("ERROR: Failed to create drop for item: " .. tostring(fromSlot.name))
    return
  end

  -- Remove the item and immediately open the drop for the player
  CreateThread(function()
    exports.ox_inventory:RemoveItem(payload.source, fromSlot.name, fromSlot.count, nil, fromSlot.slot)
    Wait(0)
    exports.ox_inventory:forceOpenInventory(payload.source, "drop", dropId)
  end)

  return false -- prevent default swap handling
end, { typeFilter = { player = true } })

-- Banner
CreateThread(function()
  Wait(1000)
  print("^2[LOADED]^7 - ^1PRODIGY INVENTORY V2^7 - CREATED BY ^5AKILLA DEVELOPMENTS^7")
end)