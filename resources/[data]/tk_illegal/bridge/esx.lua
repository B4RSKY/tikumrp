if tnm.fw.type ~= 'esx' then return end
local isServer = IsDuplicityVersion()
fw = exports[tnm.fw.namacore]:getSharedObject()
core = {}

if not isServer then
    core.SpawnObject = fw.Game.SpawnObject
else
    core.GetCountJobs = function(tipe, job)
        local jj = ESX.GetExtendedPlayers(tipe, job)
        return #jj
    end
    core.RandomString = fw.GetRandomString
end
