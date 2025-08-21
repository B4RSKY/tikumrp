return {
    Starterpack = {
        Vehicle = {
            enabled = true,
            mode = 'fixed',
            fixedModel = 'asea',
            randomPool = { 'asea', 'blista', 'panto' },
            garage = 'pillbox',
            spawnVehicle = true,
            stateOnRegister = 1,
            SpawnPoint = vector4(251.09, -1067.27, 29.3, 3.97),
        },

        Items = {
            { name = 'phone',  count = 1 },
            { name = 'radio',  count = 1 },
            { name = 'burger', count = 3 },
            { name = 'water',  count = 3 },
        },

        Target = {
            ped = {
                model = 'cs_bankman',
                coords = vec3(251.31, -1072.03, 29.30),
                heading = 340.0,
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
                    "1. **No RDM & VDM:** Do not kill or ram others without a valid RP reason.\n\n" ..
                    "2. **Fear RP:** Value your life. Act afraid when threatened.\n\n" ..
                    "3. **Metagaming & Powergaming:** Do not use out-of-character (OOC) information in-character (IC).\n\n" ..
                    "By clicking 'Claim', you confirm you will comply with all city rules.",
            button = { submit = 'Claim', cancel = 'Batal' }
        },
        RateLimitSeconds = 5,
    }
}