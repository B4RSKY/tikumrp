Keys = {
    amount = 0,
    list = {},
    holders = {},
    house = ''
}

Keys.__index = Keys

Keys.__newindex = function(self, name, fn)
    rawset(self, name, fn)
end

function Keys:new(house, keys, holders)
    local self = setmetatable({}, self)
    self.house = house
    self.holders = holders or {}
    self.list = keys or {}
    return self
end

function Keys:Delete(name)
    self.list[name] = nil
end

function Keys:Get(name)
    return name and self.list[name] or self.list
end

function Keys:Update(name, permissions, oldName)
    if oldName and oldName ~= name then
        self:Delete(oldName)
    end
    self.list[name] = permissions
end

function Keys:GetHolder(identifier)
    return identifier and self.holders[identifier] or self.holders
end

function Keys:UpdateHolder(identifier, name, keyName)
    self.holders[identifier] = { name = name, key = keyName }
end

function Keys:DeleteHolder(identifier)
    self.holders[identifier] = nil
end

--- Check Permission by key name and permission string
---@param keyName string
---@param permission string
---@return boolean
function Keys:HasPermission(keyName, permission)
    local permissionIndex = 0
    for i = 1, #KeyPermissions do
        if KeyPermissions[i] == permission then
            permissionIndex = i
            break
        end
    end

    if not self.list[keyName] then return false end

    for i = 1, #self.list[keyName] do
        if self.list[keyName][i] == permissionIndex then
            return true
        end
    end
    return false
end

--- Check has key and optional permission
---@param identifier string
---@param permission? string
---@return boolean
function Keys:HasKey(identifier, permission)
    local home = Homes[self.house]
    if home then
        if home.properties.owner == identifier then return true end
        if home.properties.complex == 'Apartment' then
            if Apartments[home.identifier]:OwnApartment() and Apartments[home.identifier]:GetOwnedApartmentId() == LocalPlayer.state.CurrentApartment then
                return true
            end
        end
        if home.properties.rent and home.properties.rent.isRented then
            if home.properties.rent.tenant == identifier then return true end
        end
        if permission then
            return self.holders[identifier] ~= nil and self:HasPermission(self.holders[identifier].key, permission)
        end
        return self.holders[identifier] ~= nil
    end
    return false
end

function Keys:GetKeyList()
    if self.list then
        local list = {}
        local holders = {}
        for k, v in pairs(self.list) do
            list[#list + 1] = { name = k, permissions = v }
        end
        for k, v in pairs(self.holders) do
            holders[#holders + 1] = { identifier = k, name = v.name, key = v.key }
        end
        return {
            keys = list,
            holders = holders
        }
    else
        return {}
    end
end
