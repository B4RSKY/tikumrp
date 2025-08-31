return {
    Starterpack = {
        Vehicle = {
            enabled = true,
            mode = 'fixed',
            fixedModel = 'asea',
            randomPool = { 'asea', 'blista', 'panto' },
            garage = 'garasi_a',
            spawnVehicle = true,
            stateOnRegister = 1,
            SpawnPoint = vec4(-1037.37, -2726.46, 20.15, 232.96),
        },

        Items = {
            { name = 'phone',  count = 1 },
            { name = 'naspad', count = 10 },
            { name = 'esjeruk',  count = 10 },
            { name = 'tiketoplas',  count = 1 },
        },

        Target = {
            ped = {
                model = 'cs_bankman',
                coords = vec3(-1038.78, -2731.21, 20.17),
                heading = 235.14,
                scenario = 'WORLD_HUMAN_CLIPBOARD',
                freeze = true
            },
            label = 'Claim Starter Pack',
            icon = 'fa-solid fa-gift',
            distance = 2.0
        },

        Rules = {
            header = 'Konfirmasi Starter Pack',
            text = "Selamat datang di kota TITIK KUMPUL! Silakan baca dan setujui aturan di bawah ini.:\n\n" ..
                    "1. **No RDM & VDM:** Jangan membunuh atau menabrak orang lain tanpa alasan RP yang sah.\n\n" ..
                    "2. **Fear RP:** Hargai hidupmu. Bertindaklah takut saat terancam.\n\n" ..
                    "3. **Metagaming & Powergaming:** Jangan gunakan informasi di luar karakter (OOC) di dalam karakter (IC).\n\n" ..
                    "Dengan mengklik 'Klaim', Anda mengonfirmasi bahwa Anda akan mematuhi semua peraturan kota.",
            button = { submit = 'Klaim', cancel = 'Batal' }
        },
        RateLimitSeconds = 5,
    }
}