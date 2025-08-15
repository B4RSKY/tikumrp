ox_inventory = exports.ox_inventory
taneman = {}

lib.callback.register('tk-illegal:nanem:pakebibit', function(source, name)
    local src = source
    local ped = GetPlayerPed(src)
    local coord = GetEntityCoords(ped)
    if tnm.jenis[name].polisi and tnm.jenis[name].polisi > 0 then
        local jumlahPolisi = core.GetCountJobs('job', 'police')
        if jumlahPolisi < tnm.jenis[name].polisi then
            TriggerClientEvent('tk-illegal:nanem:notifikasi', src, 'Kekurangan jumlah kepolisian!', 'error')
            return false
        end
    end
    if ox_inventory:RemoveItem(src, name, 1) then
        local meta = core.RandomString(10)
        local waktu = tnm.jenis[name].waktu
        if Player(src).state.diDalamRumah and tnm.jenis[name].rumah then
            waktu = tnm.jenis[name].rumah.waktu
        end
        taneman[meta] = {
            coords = coord,
            bibit = name,
            hasil = tnm.jenis[name].hasil,
            waktu = os.time() + waktu,
            meta = meta
        }
        return true, taneman[meta]
    end
end)

lib.callback.register('tk-illegal:nanem:updateEntity', function(source, meta, net)
    taneman[meta].net = net
    return true
end)

lib.callback.register('tk-illegal:nanem:cekTaneman', function(source, net)
    local src = source
    for k,v in pairs(taneman) do
        if v.net == net then
            return v, (v.waktu - os.time())
        end
    end
    return false
end)

lib.callback.register('tk-illegal:nanem:panen', function(source, meta)
    local src = source
    local ped = GetPlayerPed(src)
    local coord = GetEntityCoords(ped)
    -- local meta = NetworkGetEntityFromNetworkId(ent)

    -- if #(taneman.[meta].coords - coord) < 10.0 then
        if tnm.jenis[taneman[meta].bibit].polisi and tnm.jenis[taneman[meta].bibit].polisi > 0 then
            local jumlahPolisi = core.GetCountJobs('job', 'police')
            if jumlahPolisi < tnm.jenis[taneman[meta].bibit].polisi then
                TriggerClientEvent('tk-illegal:nanem:notifikasi', src, 'Kekurangan jumlah kepolisian!', 'error')
                return false
            end
        end
        local brp = (type(tnm.jenis[taneman[meta].bibit].berapa) == 'table') and math.random(tnm.jenis[taneman[meta].bibit].berapa.min, tnm.jenis[taneman[meta].bibit].berapa.max) or tnm.jenis[taneman[meta].bibit].berapa
        if Player(src).state.diDalamRumah and tnm.jenis[taneman[meta].bibit].rumah then
            brp = (type(tnm.jenis[taneman[meta].bibit].rumah.berapa) == 'table') and math.random(tnm.jenis[taneman[meta].bibit].rumah.berapa.min, tnm.jenis[taneman[meta].bibit].rumah.berapa.max) or tnm.jenis[taneman[meta].bibit].rumah.berapa
        end
        ox_inventory:AddItem(src, tnm.jenis[taneman[meta].bibit].hasil, brp)
        if tnm.jenis[taneman[meta].bibit].dropbibit then
            local brpdrop = (type(tnm.jenis[taneman[meta].bibit].dropbibit) == 'table') and math.random(tnm.jenis[taneman[meta].bibit].dropbibit.min, tnm.jenis[taneman[meta].bibit].dropbibit.max) or tnm.jenis[taneman[meta].bibit].dropbibit
            if Player(src).state.diDalamRumah and tnm.jenis[taneman[meta].bibit].rumah then
                brpdrop = (type(tnm.jenis[taneman[meta].bibit].rumah.dropbibit) == 'table') and math.random(tnm.jenis[taneman[meta].bibit].rumah.dropbibit.min, tnm.jenis[taneman[meta].bibit].rumah.dropbibit.max) or tnm.jenis[taneman[meta].bibit].rumah.dropbibit
            end
            if brpdrop >= 1 then
                ox_inventory:AddItem(src, taneman[meta].bibit, brpdrop)
            end
        end
        taneman[meta] = nil
        return true
    -- end
end)

exports('dalamRumah', function(src)
    Player(src).state.diDalamRumah = true
end)

exports('keluarRumah', function(src)
    Player(src).state.diDalamRumah = false
end)