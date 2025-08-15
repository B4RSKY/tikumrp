ox_inventory = exports.ox_inventory

netEntity = function(entity)
    local pm = promise.new()
    repeat NetworkRegisterEntityAsNetworked(entity) Wait(0) until NetworkGetEntityIsNetworked(entity)
    pm:resolve({true, ObjToNet(entity)})
    return Citizen.Await(pm)
end

HapusObjek = function(entity, isnetwork)
    if not isnetwork then
        NetworkRequestControlOfEntity(entity)
        -- entity = entityHandler
        while not NetworkRequestControlOfEntity(entity) do
            Citizen.Wait(1)
        end

        if not IsEntityAMissionEntity(entity) then
            SetEntityAsMissionEntity(entity)
        end

        DeleteEntity(entity)
    else
        -- entity = networkID
        NetworkRequestControlOfNetworkId(entity)
        
        local new_entity = NetworkGetEntityFromNetworkId(entity)

        while not NetworkRequestControlOfEntity(new_entity) do
            Citizen.Wait(1)
        end

        SetEntityAsMissionEntity(new_entity)
        DeleteEntity(new_entity)
    end
end

local function panenTaneman(data)
    local net = netEntity(data.entity)
    local cekTaneman, sisaWaktu = lib.callback.await('tk-illegal:nanem:cekTaneman', false, net[2])
    if cekTaneman then
        if sisaWaktu < 0 then
            if tnm.jenis[cekTaneman.bibit].minigame and tnm.jenis[cekTaneman.bibit].posisiMinigame.panen then
                local success = lib.skillCheck(tnm.jenis[cekTaneman.bibit].minigame, {'e'})
                if not success then return end
            end
            if lib.progressBar({
                duration = tnm.progress.panen.durasi,
                label = (tnm.progress.panen.label):format(ox_inventory:Items()[cekTaneman.hasil].label),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    combat = true,
                    move = true,
                    car = true
                },
                anim = tnm.progress.panen.anim
            })
            then
                local panen = lib.callback.await('tk-illegal:nanem:panen', false, cekTaneman.meta)
                if panen then
                    HapusObjek(cekTaneman.net, true)
                end
            end
        else
            lib.notify({
                title = 'Tanaman',
                description = ('Tanaman ini masih numbuh (%s detik lagi)'):format(sisaWaktu),
                type = 'error',
            })
        end
    end
end

CreateThread(function()
    for k,v in pairs(tnm.jenis) do
        exports.ox_target:addModel(v.model, {
            {
                label = 'Panen '..ox_inventory:Items()[v.hasil].label,
                icon = 'fas fa-seedling',
                distance = 1.5,
                onSelect = function(data)
                    panenTaneman(data)
                end,
                canInteract = function(entity)
                    local net = netEntity(entity)
                    local cekTaneman, sisaWaktu = lib.callback.await('tk-illegal:nanem:cekTaneman', false, net[2])
                    if cekTaneman then return true end
                end
            }
        })
    end
end)

RegisterNetEvent('tk-illegal:nanem:useItem', function(data)
    local meta = tnm.jenis[data.name]
    if meta and (#(meta.coords - GetEntityCoords(cache.ped)) < meta.distance) or (LocalPlayer.state.diDalamRumah and meta.rumah) then
        local pakaiBibit, data1 = lib.callback.await('tk-illegal:nanem:pakebibit', false, data.name)
        if pakaiBibit then
            if tnm.jenis[data.name].minigame and tnm.jenis[data.name].posisiMinigame.nanem then
                local success = lib.skillCheck(tnm.jenis[data.name].minigame, {'e'})
                if not success then return end
            end
            if lib.progressBar({
                duration = tnm.progress.nanem.durasi,
                label = (tnm.progress.nanem.label):format(ox_inventory:Items()[data.name].label),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    combat = true,
                    move = true,
                    car = true
                },
                anim = tnm.progress.nanem.anim
            })
            then
                local x,y,z = table.unpack(GetEntityCoords(cache.ped))
                core.SpawnObject(meta.model, vec3(x,y,z - meta.turun), function(object)
                    local net = netEntity(object)
                    if net[1] then
                        FreezeEntityPosition(object, true)
                        local saved = lib.callback.await('tk-illegal:nanem:updateEntity', false, data1.meta, net[2])
                        if saved then
                            lib.notify({
                                title = 'Tanaman',
                                description = 'Tanaman ini berhasil tertanam',
                                type = 'success',
                            })
                        end
                    end
                end)
            end
        end
    else
        lib.notify({
            title = 'Tanaman',
            description = 'Tanaman ini tidak bisa ditanam di daerah sini',
            type = 'error'
        })
    end
end)

RegisterNetEvent('tk-illegal:nanem:notifikasi', function(msg, tipe)
    lib.notify({
        title = 'Tanaman',
        description = msg,
        type = tipe
    })
end)