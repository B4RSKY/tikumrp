if tnm.fw.type ~= 'qb' then return end
local isServer = IsDuplicityVersion()
fw = exports[tnm.fw.namacore]:GetCoreObject()
core = {}

if not isServer then
     core.SpawnObject_satu = function(model, ...)
        local modelHash = model

        if type(model) == "string" then
            modelHash = GetHashKey(model)
        end

        if not IsModelValid(modelHash) then
            error("Model \""..model.."\" loaded from \""..GetCurrentResourceName().."\" is not valid^0")
            return
        end

        lib.requestModel(modelHash, 1500)

        local obj = CreateObject(modelHash, ...)

        SetModelAsNoLongerNeeded(modelHash) 

        local netId = 0

        if NetworkGetEntityIsNetworked(obj) then
            netId = ObjToNet(obj)
            SetNetworkIdExistsOnAllMachines(netId, true)
            SetNetworkIdCanMigrate(netId, true)
        end

        return obj, netId
    end

    core.SpawnObject = function(model, koordinat, sukses)
        local ss = core.SpawnObject_satu(model, koordinat, true, false, false)
        if ss and sukses then
            sukses(ss)
        end
    end

else
    local charset = {}
    for c = 48, 57  do charset[#charset+1] = string.char(c) end -- 0-9
    for c = 65, 90  do charset[#charset+1] = string.char(c) end -- A-Z
    for c = 97, 122 do charset[#charset+1] = string.char(c) end -- a-z
    
    core.GetCountJobs = function(_, namajob)
        local count = 0
        local players = {}
        for _, v in pairs(fw.Functions.GetQBPlayers()) do
            if v then
                if v.PlayerData.job.name == namajob and v.PlayerData.job.onduty then
                    count += 1
                end
    
                players[v.PlayerData.source] = {}
                players[v.PlayerData.source].optin = fw.Functions.IsOptin(v.PlayerData.source)
            end
        end
        return count
    end
    core.RandomString = function(len)
        if not len or len <= 0 then return '' end
        local t = table.create and table.create(len, 0) or {}
        for i = 1, len do
            t[i] = charset[math.random(#charset)]
        end
        return table.concat(t)
    end
end
