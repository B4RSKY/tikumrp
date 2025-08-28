Config = {}
--Jobcenter
Config.Disnaker = {
    model = 'a_m_y_business_02',
    coords = vector4(-435.05, 1097.65, 326.77, 351.12),
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

Config.Jobs = {
    ['unemployed'] = {
        label = 'Pengangguran',
        description = 'Lepaskan pekerjaanmu saat ini.',
        icon = 'fa-solid fa-user-slash'
    },
    ['tailor'] = {
        label = 'Penjahit',
        description = 'Membuat baju untuk seluruh warga di kota.',
        icon = 'fas fa-tshirt'
    },
    ['miner'] = {
        label = 'Penambang',
        description = 'Dapatkan permata agar menjadi kaya.',
        icon = 'fas fa-pickaxe'
    },
    ['slaughterer'] = {
        label = 'Tukang Ayam',
        description = 'JagBekerja sebagai tukang ayam untuk kebutuhan makanan di kota.',
        icon = 'fas fa-drumstick-bite'
    },
    ['lumberjack'] = {
        label = 'Tukang Kayu',
        description = 'Kang potong kayu.',
        icon = 'fas fa-tree'
    },
    ['bus'] = {
        label = 'Supir Bus',
        description = 'Bekerja sebagai supir bus bisa tanpa modal.',
        icon = 'fa-solid fa-bus'
    }
}
--Jual Disnaker
Config.PedLocation = vector4(-468.49, 1129.11, 325.86, 256.5)
Config.PedModel = 'a_m_y_busicas_01'

--Bus JOb
Config.DefaultBusHash = 'pbus'
Config.DutyBus = vector3(-831.27, 1788.58, 203.58)

Config.Bus = {
    bandara_route = {
        label_rute = '🛫 Rute Bandara',
        total_pendapatan = 8000,
        bus_model = 'pbus',
        spawn_bus = {
            {x = -822.30, y = 1745.10, z = 203.40, h = 229.18}
        },
        rute = {
            {
                nama = 'Balai Kota',
                coords = {x = -417.72, y = 1211.22, z = 325.64}
            },
            {
                nama = 'Sisyphus Theater',
                coords = {x = 244.44, y = 1223.24, z = 229.89}
            },
            {
                nama = 'Rumah Sakit Pillbox',
                coords = {x = 274.84, y = -584.54, z = 43.14}
            },
            {
                nama = 'Grove Street',
                coords = {x = 167.35, y = -1353.94, z = 29.30}
            },
            {
                nama = 'Los Santos International Airport',
                coords = {x = -1042.85, y = -2727.64, z = 20.17}
            },
            {
                nama = 'Kantor Pusat',
                coords = {x = -1098.54, y = -1988.35, z = 13.08}
            },
            {
                nama = 'Pelabuhan Los Santos',
                coords = {x = -788.91, y = -1282.80, z = 5.00}
            },
            {
                nama = 'Mount Zonah Medical Center',
                coords = {x = -1739.72, y = -527.30, z = 37.79}
            },
            {
                nama = 'Perumahan Richman',
                coords = {x = -1900.89, y = 703.71, z = 127.81}
            },
            {
                nama = 'Terminal Bus',
                coords = {x = -781.64, y = 971.81, z = 237.16}
            }
        }
    },
    
    paleto_route = {
        label_rute = '🏔️ Rute Paleto Bay (Via Tol)',
        total_pendapatan = 12000,
        bus_model = 'pbus',
        spawn_bus = {
            {x = -822.30, y = 1745.10, z = 203.40, h = 229.18}
        },
        rute = {
            {
                nama = 'Kantor Asuransi',
                coords = {x = 301.72, y = 2611.77, z = 44.48}
            },
            {
                nama = 'Warung Asuransi',
                coords = {x = 1105.70, y = 2678.06, z = 38.54}
            },
            {
                nama = 'Bengkel Sandy Shores',
                coords = {x = 1807.49, y = 3328.98, z = 41.69}
            },
            {
                nama = 'Kantor Polisi Sandy Shores',
                coords = {x = 1850.48, y = 3651.90, z = 34.11}
            },
            {
                nama = 'Warung Route 68',
                coords = {x = 1675.18, y = 4938.40, z = 42.12}
            },
            {
                nama = 'Kantor Polisi Paleto Bay',
                coords = {x = -413.75, y = 6053.12, z = 31.58}
            },
            {
                nama = 'Pusat Kota Paleto Bay',
                coords = {x = -229.90, y = 6291.31, z = 31.46}
            },
            {
                nama = 'Rest Area Tol',
                coords = {x = 1480.80, y = 6436.37, z = 22.07}
            },
            {
                nama = 'Pom Bensin Route 68',
                coords = {x = 2691.81, y = 4375.72, z = 46.77}
            },
            {
                nama = 'Bengkel Utama Sandy Shores',
                coords = {x = 1772.69, y = 3356.06, z = 40.20}
            },
            {
                nama = 'Warung Kembali',
                coords = {x = 1105.70, y = 2678.06, z = 38.54}
            },
            {
                nama = 'Kantor Asuransi (Kembali)',
                coords = {x = 301.72, y = 2611.77, z = 44.48}
            },
            {
                nama = 'Terminal Bus',
                coords = {x = -162.96, y = 1908.92, z = 198.05}
            }
        }
    },
}

Config.JobUniforms = {
    male = {
        ['tshirt_1'] = 58,  ['tshirt_2'] = 0,
        ['torso_1'] = 55,   ['torso_2'] = 0,
        ['decals_1'] = 0,   ['decals_2'] = 0,
        ['arms'] = 41,
        ['pants_1'] = 25,   ['pants_2'] = 0,
        ['shoes_1'] = 25,   ['shoes_2'] = 0,
        ['mask_1'] = 0,     ['mask_2'] = 0,
        ['chain_1'] = 0,    ['chain_2'] = 0,
        ['helmet_1'] = -1,  ['helmet_2'] = 0,
        ['glasses_1'] = 0,  ['glasses_2'] = 0
    },
    female = {
        ['tshirt_1'] = 35,  ['tshirt_2'] = 0,
        ['torso_1'] = 48,   ['torso_2'] = 0,
        ['decals_1'] = 0,   ['decals_2'] = 0,
        ['arms'] = 44,
        ['pants_1'] = 34,   ['pants_2'] = 0,
        ['shoes_1'] = 27,   ['shoes_2'] = 0,
        ['mask_1'] = 0,     ['mask_2'] = 0,
        ['chain_1'] = 0,    ['chain_2'] = 0,
        ['helmet_1'] = -1,  ['helmet_2'] = 0,
        ['glasses_1'] = 0,  ['glasses_2'] = 0
    }
}

--Blip
Config.Blips = {
    --DISNAKER
    {
        name = "[T.AYAM] - AMBIL AYAM", sprite = 484, color = 5, scale = 0.7,
        coords = vector3(2378.22, 5053.38, 46.44),
        jobs = {"slaughterer"}
    },
    {
        name = "[T.AYAM] - PABRIK AYAM (PROSES)", sprite = 484, color = 5, scale = 0.7,
        coords = vector3(-96.92, 6205.56, 31.03),
        jobs = {"slaughterer"}
    },
    {
        name = "[PENJAHIT] - AMBIL BENANG", sprite = 366, color = 4, scale = 0.7,
        coords = vector3(1961.04, 5185.08, 47.96),
        jobs = {"tailor"}
    },
    {
        name = "[PENJAHIT] - PABRIK BENANG (PROSES)", sprite = 366, color = 4, scale = 0.7,
        coords = vector3(713.32, -969.72, 30.4),
        jobs = {"tailor"}
    },
    {
        name = "[T.KAYU] - AMBIL KAYU", sprite = 237, color = 4, scale = 0.7,
        coords = vector3(-544.14, 5488.69, 62.92),
        jobs = {"lumberjack"}
    },
    {
        name = "[T.KAYU] - PROSES KAYU", sprite = 237, color = 4, scale = 0.7,
        coords = vector3(-533.15, 5292.14, 74.17),
        jobs = {"lumberjack"}
    },
    {
        name = "[T.KAYU] - KEMAS KAYU", sprite = 237, color = 4, scale = 0.7,
        coords = vector3(-573.14001464844, 5364.0390625, 70.209442138672),
        jobs = {"lumberjack"}
    },
    {
        name = "[PENAMBANG] - AMBIL BATU", sprite = 68, color = 5, scale = 0.7,
        coords = vector3(2948.69, 2792.83, 40.71),
        jobs = {"miner"}
    },
    {
        name = "[PENAMBANG] - CUCI BATU", sprite = 68, color = 5, scale = 0.7,
        coords = vector3(2408.96, 4412.94, 30.78),
        jobs = {"miner"}
    },
    {
        name = "[PENAMBANG] - LEBUR BATU", sprite = 68, color = 5, scale = 0.7,
        coords = vector3(1085.2, -2002.32, 31.4),
        jobs = {"miner"}
    },
    {
        name = "[SUPIR BUS] - TERMINAL", sprite = 513, color = 4, scale = 0.7,
        coords = vector3(-831.27, 1788.58, 203.58),
        jobs = {"bus"}
    },
    --UMUM
    {
        name = "Disnaker/Kantor Walikota", sprite = 590, color = 64, scale = 0.7,
        coords = vector3(-425.604401, 1123.938477, 325.836670),
        jobs = false
    },
    {
        name = "Bengkel | Mekanik", sprite = 643, color = 2, scale = 0.7,
        coords = vector3(-908.26, -2057.04, 9.3),
        jobs = false
    },
    {
        name = "Gudang", sprite = 473, color = 3, scale = 0.7,
        coords = vector3(903.07, 3586.16, 33.43),
        jobs = false
    },
    {
        name = "Gudang", sprite = 473, color = 3, scale = 0.7,
        coords = vector3(-1607.43, -830.21, 10.08),
        jobs = false
    },
    {
        name = "Zona Santai", sprite = 621, color = 1, scale = 0.7,
        coords = vector3(-1840.15, -1216.46, 13.02),
        jobs = false
    },
}