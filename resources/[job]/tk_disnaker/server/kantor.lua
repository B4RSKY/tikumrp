local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('tk-disnaker:dapatJob', function(jobName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Config.Jobs[jobName] then return end

    local jobLabel = Config.Jobs[jobName].label
    local oldJob = Player.PlayerData.job.label

    Player.Functions.SetJob(jobName, 0)

    TriggerClientEvent('QBCore:Notify', src, 'DISNAKER', ('Anda telah mengganti pekerjaan dari %s menjadi %s.'):format(oldJob, jobLabel), 'success', 5000)
end)