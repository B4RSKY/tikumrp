return {
    [`WEAPON_PISTOL`] = {
        damage = 0.1,
        recoil = 4.5,
        camShake = 0.1,
        onShooting = function ()
            -- if math.random() < 0.1 then
            --     TriggerServerEvent('hud:server:GainStress', math.random(10, 20))
            -- end
            TriggerServerEvent('hud:server:GainStress', math.random(10, 20))
        end
    },
    [`WEAPON_PISTOL50`] = {
        damage = 0.1,
        recoil = 4.5,
        camShake = 0.8,
    }
}