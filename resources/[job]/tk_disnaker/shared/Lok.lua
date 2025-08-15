Lokasi = {
    Ayam = {
        --Ambil
        dapatAyam = 1,
        --potong
        potongAyam = vector3(-96.92, 6205.56, 31.03),
        PotongKurang = 1,
        PotongDapat = 1,
        --Bunuh
        bunuhAyam = vector3(-78.16, 6229.34, 31.09),
        bunuhKurang = 1,
        bunuhDapat = 1,
        --Kemas
        kemasAyam = vector3(-104.04, 6206.88, 31.03),
        kemasAyamDapat = 1,
        kemasAyamKurang = 1,
    },
    Penjahit = {
        --Ambil Benang
        AmbilBenang = vector3(1961.04, 5185.08, 47.96),
        dapatBenang = 1,
        --Proses
        Jahit = vector3(713.32, -969.72, 30.4),
        prosesBenangKurang = 1,
        prosesBenangDapat = 1,
        kemasJahitKurang = 1,
        kemasJahitDapat = 1,
    },
    Lumberjack = {
        --Tebang
        ZonaTebang = vector3(-544.14, 5488.69, 62.92),
        ZoneRadius = 50.0,
        MaxPohon = 10,
        TreeModel = 'prop_w_r_cedar_dead',
        dapatWood = {min = 2, max = 4},
        respawnPohon = 30000,
        OutlineColor = {r = 0, g = 255, b = 0, a = 255},
        autoTebangTime = 1 * 60 * 1000,
        autoTebangCD = 15 * 60 * 1000,
        --Potong Kayu
        prosesKayu = vector3(-533.15, 5292.14, 74.17),
        ProsesKurang = 1,
        ProsesDapat = 1,
        --Kemas Kayu
        kemasKayu = vec3(-573.14001464844, 5364.0390625, 70.209442138672),
        kemasKurang = 1,
        kemasDapat = 1,

    },
    Miner = {
        ambilBatu = vector3(2948.69, 2792.83, 40.71),
        dapatBatu = 1,
        cuciBatu = vector3(2408.96, 4412.94, 30.78),
        cuciKurang = 1,
        cuciDapat = 2,
        leburBatu = vector3(1085.2, -2002.32, 31.4),
    },
}