Config = {}

Config.ItemName            = 'identification'
Config.UseMugshotBase64    = true
Config.MaxDistanceToTarget = 4.5
Config.MaxValidityDays     = 365 * 1
Config.RateLimitSeconds    = 5

Config.LicenseTypes = {
    identification = {
        title = 'KTP',
        item  = 'identification',
        default_days = 30,
        allow_self_service = true,
        require_photo = true
    },
    driver_license = {
        title = 'SIM',
        item  = 'driver_license',
        default_days = 30,
        allow_self_service = false,
        require_photo = true
    },
    firearms_license = {
        title = 'Lisensi Senjata',
        item  = 'firearms_license',
        default_days = 30,
        allow_self_service = false,
        require_photo = true
    },
    kartu_pasien = {
        title = 'Kartu Pasien',
        item  = 'patient_card',
        default_days = 30,
        allow_self_service = false,
        require_photo = false
    },
}

if not IsDuplicityVersion() then
    Config.Client = {}
    Config.Client.AllowedJobs = {
        police     = 2,
        realestate = 0,
        -- admin   = 0,
    }

    Config.Client.OfficerStations = {
        {
            id = 'cityhall_officer',
            mode = 'ped',
            coords = vector3(-438.46, 1086.44, 329.77),
            heading = 349.38,
            pedModel = `a_m_y_business_01`,
            scenario = 'WORLD_HUMAN_CLIPBOARD',
            label = 'Buat KTP',
            icon  = 'fa-solid fa-id-card',
            distance = 2.0
        },
        {
            id = 'mrpd_officer_zone',
            mode   = 'zone',
            center = vec3(441.15, -981.89, 30.69),
            length = 2.2, width = 2.6,
            heading = 0.0, minZ = 29.69, maxZ = 32.29,
            label  = 'Layanan KTP (Petugas)',
            icon   = 'fa-solid fa-id-card',
            distance = 2.0
        },
    }

    Config.Client.SelfStations = {
        {
            id = 'ktp_mandiri',
            mode = 'ped',
            coords = vector3(-430.85, 1096.46, 326.77),
            heading = 340.1,
            pedModel = `a_m_y_business_01`,
            scenario = 'WORLD_HUMAN_STAND_MOBILE',
            label = 'Request KTP',
            icon = 'fa-solid fa-id-card', 
            distance=2.0
        }
    }
end

if IsDuplicityVersion() then
    Config.Server = Config.Server or {}
    Config.Server.UseLicenseTable = true
    Config.Server.AllowedJobs = {
        police     = 2,
        realestate = 0,
        -- admin   = 0,
    }
    Config.Server.Permissions = {
        police = {
            min_grade = 2,
            jenis_license = { 'driver_license', 'firearms_license' },
        },
        realestate = {
            min_grade = 0,
            jenis_license = { 'identification' },
        },
        ambulance = {
            min_grade = 0,
            jenis_license = { 'bpjs', 'kartu_pasien' },
        },
    }

Config.Server.DefaultIssueLocks = Config.Server.DefaultIssueLocks or {}
    Config.Server.RemoveOldOnReissue = true
    Config.Server.Webhook = 'https://discord.com/api/webhooks/1405049392322445312/9Kw0wExu9_oK79KXbtsMTPDmaVKHEQUuLjYKZZeKfvshuf6mgOL1ywMkljAEK-rZqSWh' -- isi kalau mau log ke Discord
end
