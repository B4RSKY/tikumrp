function round(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 2) .. "f", num))
end

function RoundCoordinates(coords)
  return { x = round(coords.x, 3), y = round(coords.y, 3), z = round(coords.z, 3) }
end

---Extract Home Id & optional Apartment Id
---@param data {homeId: string, aptId: string} | string
---@return string, string?
function GetHomeAptId(data)
  if type(data) == 'table' then
    return data.homeId, data.aptId
  else
    return data
  end
end

function TableContainsKey(tbl, value)
  if type(tbl) ~= 'table' then return false end
  for key, _ in pairs(tbl) do
    if type(value) == 'table' then
      for i = 1, #value do
        if key == value[i] then
          return true, key
        end
      end
    else
      if key == value then
        return true, key
      end
    end
  end
  return false
end

function TableContainsValue(tbl, value)
  if type(tbl) ~= 'table' then return false end
  for _, key in pairs(tbl) do
    if key == value then
      return true
    end
  end
  return false
end

function GetTargetScript()
  if IsResourceStarted(Config.exportname.ox_target) then
    return Config.exportname.ox_target
  elseif IsResourceStarted(Config.exportname.qtarget) then
    return Config.exportname.qtarget
  elseif IsResourceStarted(Config.exportname.qbtarget) then
    return Config.exportname.qbtarget
  end
end

function IsResourceStarted(resource)
  return GetResourceState(resource) == 'started'
end

---Converts & confirms a table
---@param value any
---@return table
function ConvertToTable(value)
  if type(value) == 'table' then
    return value
  else
    return json.decode(value)
  end
end

---@param value {x: number, y:number, z:number}
---@return vector3
function ToVector3(value)
  return value and vec3(value.x or 0.0, value.y or 0.0, value.z or 0.0) or nil
end

---@param value {x: number, y:number, z:number, w:number}
---@return vector4
function ToVector4(value)
  return value and vec4(value.x or 0.0, value.y or 0.0, value.z or 0.0, value.w or 0.0) or nil
end

function ReturnDefaultValueNil(value, default)
  if value ~= nil then
    return value
  else
    return default
  end
end

function SplitString(input, separator)
  local result = {}
  for match in input:gmatch("([^" .. separator .. "]+)") do
    table.insert(result, match)
  end
  return result
end

function GetNestedValue(tbl, keys)
  local value = tbl
  for _, key in ipairs(keys) do
    if value[key] then
      value = value[key]
    else
      return nil -- Return nil if key does not exist
    end
  end
  return value
end

function FindEntitySetData(entry)
  local nearest = 50
  local data = {}
  for i = 1, #Config.EntitySet do
    local dist = #(Config.EntitySet[i].coords - entry)
    if dist < nearest then
      data = Config.EntitySet[i]
      nearest = dist
    end
  end
  return data
end

local timeOuts = {}

function SetTimeOut(delay, callback)
  local id = #timeOuts + 1

  timeOuts[id] = true

  CreateThread(function()
    Wait(delay)
    if timeOuts[id] then
      timeOuts[id] = nil
      if callback then
        callback()
      end
    end
  end)

  return id
end

function ClearTimeOut(id)
  if timeOuts[id] then
    timeOuts[id] = nil
    return true
  end
  return false
end

function Lerp(a, b, t)
  return a + (b - a) * t
end
