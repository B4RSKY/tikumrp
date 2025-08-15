return {
    Proses = {
        {
            id = 'proc_micin',
            label = 'Proses Micin',
            coords = vec3(2326.86, 2569.48, 46.68),
            radius = 2.0,
            duration = 7000,
            isJobs = {},
            isGeng = {},
            resep = {{ input = 'bubuk_ketawa', inCount = 1, output = 'micin', outCount = 1, label = 'Proses bubuk ketawa → micin' }},

            anim = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 49 },
            scenario = nil,
        }, {
            id = 'proc_micin_turbo',
            label = 'Proses Micin Turbo',
            coords = vec3(2326.86, 2569.48, 46.68),
            radius = 2.0,
            duration = 7000,
            isJobs = {},
            isGeng = {},
            resep = {{ input = 'micin', inCount = 1, output = 'micin_turbo', outCount = 1, label = 'Proses Micin → Micin Turbo' }},

            anim = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 49 },
            scenario = nil,
        }, {
            id = 'proc_biji_pelangi',
            label = 'Proses Biji Pelangi',
            coords = vec3(2326.86, 2569.48, 46.68),
            radius = 2.0,
            duration = 7000,
            isJobs = {},
            isGeng = {},
            resep = {{ input = 'biji_pelangi', inCount = 1, output = 'bubuk_kopihyper', outCount = 1, label = 'Proses Biji Pelangi → Bubuk Kopi Hyper' }},

            anim = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 49 },
            scenario = nil,
        }, {
            id = 'porc_kopihyper',
            label = 'Proses Kopi Hyper',
            coords = vec3(2326.86, 2569.48, 46.68),
            radius = 2.0,
            duration = 7000,
            isJobs = {},
            isGeng = {},
            resep = {{ input = 'bubuk_kopihyper', inCount = 1, output = 'kopi_hyper', outCount = 1, label = 'Proses Bubuk Kopi Hyper → Kopi Hyper' }},

            anim = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 49 },
            scenario = nil,
        },
    },
    FinishTolerance = 2.5
}