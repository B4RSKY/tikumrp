return {
    JobVehicleShop = {
        --POLISI
        {
            job = 'police',
            label = 'Dealer Polisi',
            ped = {
                model = 'csb_cop',
                coords = vector4(311.13, -1452.61, 29.97, 55.67)
            },
            spawn = vector4(297.23, -1440.6, 29.8, 229.49),
            vehicle = {
                police = {
                    price = 15000,
                    label = 'KLX 150',
                    prefixPlate = 'POL',
                    forRank = {
                        [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true, [16] = true,
                    }
                },
            }
        },
        {
            job = 'ambulance',
            label = 'Dealer Heli EMS',
            ped = {
                model = 's_m_m_doctor_01',
                coords = vector4(-463.76, -962.86, 39.78, 171.78)
            },
            spawn = vector4(-458.86, -953.44, 41.49, 188.0),
            vehicle = {
                swift = {
                    price = 20000,
                    label = 'Helikopter',
                    prefixPlate = 'EMS',
                    forRank = {
                        [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true, [16] = true,
                    }
                },
            }
        },
        {
            job = 'ambulance',
            label = 'Dealer EMS',
            ped = {
                model = 's_m_m_doctor_01',
                coords = vector4(-431.61, -959.58, 23.69, 2.51)
            },
            spawn = vector4(-430.66, -955.76, 23.7, 352.67),
            vehicle = {
                ambulance = {
                    price = 5000,
                    label = 'Ambulance',
                    prefixPlate = 'EMS',
                    forRank = {
                        [0] = true, [1] = true, [2] = true, [3] = true
                    }
                },
                gsemsrj = {
                    price = 2500,
                    label = 'BMR R 1200 SG',
                    prefixPlate = 'EMS',
                    forRank = {
                        [0] = true, [1] = true, [2] = true, [3] = true
                    }
                },
                hiluxamb = {
                    price = 5000,
                    label = 'Toyata Hulix',
                    prefixPlate = 'EMS',
                    forRank = {
                        [0] = true, [1] = true, [2] = true, [3] = true
                    }
                },
                sanchezems = {
                    price = 2500,
                    label = 'Sanchez',
                    prefixPlate = 'EMS',
                    forRank = {
                        [0] = true, [1] = true, [2] = true, [3] = true
                    }
                },
            }
        },
    }
}