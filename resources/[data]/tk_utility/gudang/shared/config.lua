local Cfg = {
    Lokasi = {
        Kota = {
            label  = "Gudang Kota",
            name   = "Kota",
            coords = vec4(-1607.43, -830.21, 10.08, 143.97),
            defaultWeight = 500000,
            defaultSlots  = 150,
            target = { label = "Gudang", icon = "fa-solid fa-warehouse" }
        },
        SandyShores = {
            label  = "Gudang SS",
            name   = "SandyShores",
            coords = vec4(903.07, 3586.16, 33.43, 181.26),
            defaultWeight = 500000,
            defaultSlots  = 150,
            target = { label = "Gudang", icon = "fa-solid fa-warehouse" }
        },
    },

    RentOptions = {
        ["1w"] = { label = "1 Minggu",  duration = 7  * 24 * 60 * 60 },
        ["2w"] = { label = "2 Minggu",  duration = 14 * 24 * 60 * 60 },
        ["1m"] = { label = "1 Bulan",   duration = 30 * 24 * 60 * 60 },
    },

    GracePeriod = 2 * 24 * 60 * 60,
    UpgradePlans = {
        u500  = { label = "Upgrade +250 KG & +50 Slot",  addWeight = 250000,  addSlots = 50  },
        u750  = { label = "Upgrade +400 KG & +75 Slot",  addWeight = 400000,  addSlots = 75  },
        u1000 = { label = "Upgrade +550 KG & +100 Slot", addWeight = 550000, addSlots = 100 },
    },
}

if IsDuplicityVersion() then
    Cfg.RentOptions["1w"].harga = 150000
    Cfg.RentOptions["2w"].harga = 300000
    Cfg.RentOptions["1m"].harga = 500000

    Cfg.UpgradePlans.u500.harga  = 750000
    Cfg.UpgradePlans.u750.harga  = 1000000
    Cfg.UpgradePlans.u1000.harga = 1500000

    return {
        Lokasi = Cfg.Lokasi,
        RentOptions = Cfg.RentOptions,
        GracePeriod = Cfg.GracePeriod,
        UpgradePlans = Cfg.UpgradePlans,
        WebhookURL = Cfg.WebhookURL
    }
else
    local clientLokasi = {}
    for k, v in pairs(Cfg.Lokasi) do
        clientLokasi[k] = { label = v.label, name = v.name, coords = v.coords, target = v.target }
    end

    local clientRent = {}
    for k, v in pairs(Cfg.RentOptions) do
        clientRent[k] = { label = v.label, duration = v.duration }
    end

    local clientUpgrade = {}
    for k, v in pairs(Cfg.UpgradePlans) do
        clientUpgrade[k] = { label = v.label }
    end

    return {
        Lokasi = clientLokasi,
        RentOptions = clientRent,
        GracePeriod = Cfg.GracePeriod,
        UpgradePlans = clientUpgrade
    }
end