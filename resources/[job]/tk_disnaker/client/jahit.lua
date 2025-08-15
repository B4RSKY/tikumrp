local sibukJahit = false
local QBCore = exports['qb-core']:GetCoreObject()

RegisterCommand('disnaker', function()
    TriggerServerEvent('tk-jobs:duty', cache.serverId, true)
    print('On Duty')
end)

RegisterCommand('offdisnaker', function()
    TriggerServerEvent('tk-jobs:duty', cache.serverId, false)
    print('Of Duty')
end)

local function AmbilWool()
    if not QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
        lib.notify({ title = 'DISNAKER', description = 'Ganti baju terlebih dahulu', type = 'error', duration = 3500})
        return
    end

    if sibukJahit then return end
    sibukJahit = true

    local success = lib.skillCheck({'easy'}, {'w', 'a', 's', 'd'})
    if success then
        if lib.progressBar({
            duration = 5000,
            label = 'Mengambil Benang...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false
            },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        }) then 
            disnaker('dapat', 'jahit', nil, Lokasi.Penjahit.dapatBenang)
            sibukJahit = false
        else 
            sibukJahit = false
            lib.notify({ title = 'DISNAKER', description = 'Proses dibatalkan', type = 'error', duration = 3500})
        end
    else
        sibukJahit = false
    end
end

local function ProsesBenang()
    if not QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
        lib.notify({ title = 'DISNAKER', description = 'Ganti baju terlebih dahulu', type = 'error', duration = 3500})
        return
    end

    if not exports['qb-core']:HasItem('wool', 1) then
        lib.notify({ title = 'DISNAKER', description = 'Tidak Memiliki Cukup Benang', type = 'error', duration = 3500})
        return
    end

    if sibukJahit then return end
    sibukJahit = true

    local success = lib.skillCheck({'easy'}, {'w', 'a', 's', 'd'})
    if success then
        if lib.progressBar({
            duration = 5000,
            label = 'Proses Benang...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false
            },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        }) then 
            disnaker('proses', 'jahit', Lokasi.Penjahit.prosesBenangKurang, Lokasi.Penjahit.prosesBenangDapat)
            sibukJahit = false
        else 
            sibukJahit = false
            lib.notify({ title = 'DISNAKER', description = 'Proses dibatalkan', type = 'error', duration = 3500})
        end
    else
        sibukJahit = false
    end
end

local function KemasBenang()
    if not QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] then
        lib.notify({ title = 'DISNAKER', description = 'Ganti baju terlebih dahulu', type = 'error', duration = 3500})
        return
    end

    if not exports['qb-core']:HasItem('fabric', 1) then
        lib.notify({ title = 'DISNAKER', description = 'Tidak Memiliki Cukup Kain', type = 'error', duration = 3500})
        return
    end

    if sibukJahit then return end
    sibukJahit = true

    local success = lib.skillCheck({'easy'}, {'w', 'a', 's', 'd'})
    if success then
        if lib.progressBar({
            duration = 5000,
            label = 'Menjahit Pakaian...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false
            },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        }) then 
            disnaker('kemas', 'jahit', Lokasi.Penjahit.kemasJahitKurang, Lokasi.Penjahit.kemasJahitDapat)
            sibukJahit = false
        else 
            sibukJahit = false
            lib.notify({ title = 'DISNAKER', description = 'Proses dibatalkan', type = 'error', duration = 3500})
        end
    else
        sibukJahit = false
    end
end

exports.ox_target:addBoxZone({
    coords = Lokasi.Penjahit.AmbilBenang,
    size = vec3(2, 2, 2),
    rotation = 45,
    debug = drawZones,
    options = {
        {
            icon = 'fas fa-box-open',
            label = 'Ambil Wol',
            groups = 'tailor',
            onSelect = function()
                AmbilWool()
            end,
            canInteract = function(entity) return QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] end
        }
    }
})

exports.ox_target:addBoxZone({
    coords = Lokasi.Penjahit.Jahit,
    size = vec3(2, 2, 2),
    rotation = 45,
    debug = drawZones,
    options = {
        {
            icon = 'fas fa-tshirt',
            label = 'Proses Benang',
            groups = 'tailor',
            onSelect = function()
                ProsesBenang()
            end,
            canInteract = function(entity) return QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] end
        },
        {
            icon = 'fas fa-tshirt',
            label = 'Jahit Pakaian',
            groups = 'tailor',
            onSelect = function()
                KemasBenang()
            end,
            canInteract = function(entity) return QBCore.Functions.GetPlayerData().metadata['disnakerDuty'] end
        }
    }
})