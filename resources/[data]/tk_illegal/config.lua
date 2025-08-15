tnm = {
    fw = {
        type = 'qb', -- esx / qb
        namacore = 'qb-core',
    },
    progress = { -- progressbar
        nanem = {
            label = 'Menanam %s',
            durasi = 5000,
            anim = {
                scenario = 'world_human_gardener_plant',
            }
        },
        panen = {
            label = 'Memanen %s',
            durasi = 5000,
            anim = {
                dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                clip = 'machinic_loop_mechandplayer',
            }
        }
    },
    jenis = {
        benih_micin = {
            bibit = 'benih_micin',
            hasil = 'bubuk_ketawa',
            berapa = { -- ini kalo hasilnya mau random
                min = 5,
                max = 10,
            },
            waktu = 180, -- detik
            coords = vector3(-2591.3765, 2434.2217, 1.2568),
            distance = 100.0,
            model = 'prop_weed_01', -- based on https://forge.plebmasters.de/
            turun = 1,
            minigame = {'easy'},
            posisiMinigame = {
                nanem = false,
                panen = true
            },
            dropbibit = { -- ini kalo mau drop bibit nya random
                min = 1,
                max = 2,
            },
            polisi = 0,
            rumah = { -- config ketika di dalam rumah
                waktu = 100,
                berapa = {
                    min = 1,
                    max = 3,
                },
                dropbibit = {
                    min = 0,
                    max = 1,
                },
            }
        },
        benih_bijipelangi = {
            bibit = 'benih_bijipelangi',
            hasil = 'biji_pelangi',
            berapa = { -- ini kalo hasilnya mau random
                min = 5,
                max = 10,
            },
            waktu = 180, -- detik
            coords = vector3(2904.1338, 363.9522, 2.6413),
            distance = 100.0,
            model = 'bkr_prop_meth_phosphorus',
            turun = 1,
            minigame = {'easy'}, -- kalo gamau pake minigame
            posisiMinigame = {
                nanem = false,
                panen = true
            },
            dropbibit = { -- ini kalo mau drop bibit nya random
                min = 1,
                max = 2,
            },
            polisi = 0,
            rumah = { -- config ketika di dalam rumah
                waktu = 100,
                berapa = {
                    min = 1,
                    max = 3,
                },
                dropbibit = {
                    min = 0,
                    max = 1,
                },
            }
        },
    }
}