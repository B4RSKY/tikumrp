return {
    [`WEAPON_REVOLVER_MK2`] = {
        damage = 0.6,
        recoil = 1.5,
        camShake = 1.5,
        onShooting = function ()
            if math.random() < 0.1 then
                TriggerServerEvent('hud:server:GainStress', math.random(1, 2))
            end
        end
    },
    [`WEAPON_ASSSAULTRIFLE_MK2`] = {
        damage = 0.4,
        recoil = 0.15,
        camShake = 0.3,
        onShooting = function ()
            if math.random() < 0.1 then
                TriggerServerEvent('hud:server:GainStress', math.random(1, 2))
            end
        end
    },
    [`WEAPON_MICROSMG`] = {
        damage = 0.8,
        recoil = 0.3,
        camShake = 0.1,
        onShooting = function ()
            if math.random() < 0.1 then
                TriggerServerEvent('hud:server:GainStress', math.random(1, 2))
            end
        end
    },
    [`WEAPON_MINISMG`] = {
        damage = 0.2,
        recoil = 0.1,
        camShake = 0.1,
        onShooting = function ()
            if math.random() < 0.1 then
                TriggerServerEvent('hud:server:GainStress', math.random(1, 2))
            end
        end
    },
    [`WEAPON_PISTOL50`] = {
        damage = 0.5,
        recoil = 0.3,
        camShake = 0.08,
        onShooting = function ()
            if math.random() < 0.1 then
                TriggerServerEvent('hud:server:GainStress', math.random(1, 2))
            end
        end
    },
    [`WEAPON_SNIPERRIFLE`] = {
        damage = 3.5,
        recoil = 4.5,
        camShake = 1.1,
        onShooting = function ()
            if math.random() < 0.1 then
                TriggerServerEvent('hud:server:GainStress', math.random(1, 2))
            end
        end
    }
}