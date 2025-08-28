local Config = require 'vipsystem.shared.config'

CreateThread(function()
    TriggerServerEvent('tk_vip:server:refresh')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('tk_vip:server:refresh')
end)

local function getVipMap()
    local map = LocalPlayer.state['tk_vip']
    return type(map) == 'table' and map or {}
end

exports('getVip', function()
    local map = getVipMap()
    return next(map) ~= nil
end)

exports('getVipJenis', function(jenis)
    if not jenis then return false end
    local map = getVipMap()
    return map[tonumber(jenis)] ~= nil
end)

RegisterCommand('vipadmin', function()
    local isAdmin = lib.callback.await('tk_vip:server:isAdmin', false)
    if not isAdmin then
        lib.notify({ type='error', description='Kamu bukan admin VIP.' })
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        jenis  = Config.VipSystem.VipJenis,
        maxDays= Config.VipSystem.MaxDays or 365,
        lockTo = Config.VipSystem.LockCodeToIdentifier
    })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'forceClose' })
    cb(true)
end)

RegisterNUICallback('create_code', function(data, cb)
    data = type(data) == 'table' and data or {}
    local resp = lib.callback.await('tk_vip:server:create_code', false, data)
    cb(resp or { ok=false, error='Tidak ada respon' })
end)

RegisterNUICallback('list_vip', function(data, cb)
    data = type(data) == 'table' and data or {}
    local resp = lib.callback.await('tk_vip:server:list', false, data)
    cb(resp or { ok=false, error='Tidak ada respon' })
end)

RegisterNUICallback('revoke_vip', function(data, cb)
    data = type(data) == 'table' and data or {}
    TriggerServerEvent('tk_vip:server:revoke', data)
    cb({ ok=true })
end)

-- penggunaan
-- -- server
-- if exports.tk_vip:getVip(source) then ... end
-- if exports.tk_vip:getVipJenis(source, 2) then ... end

-- -- client
-- if exports.tk_vip:getVip() then ... end
-- if exports.tk_vip:getVipJenis(2) then ... end