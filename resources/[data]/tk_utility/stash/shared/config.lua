local Cfg = {
    Stash = {
        ['brankas_polisi'] = {
            label = 'Brankas Polisi',
            slots = 200,
            weight = 1000000,
            jobs = 'police',
            withdraw_grade = 0,
            deposit_grade = 0,
            target = false
        },
        ['brankas_ems'] = {
            label = 'Brankas Medis',
            slots = 200,
            weight = 1000000,
            jobs = 'ambulance',
            withdraw_grade = 1,
            deposit_grade = 0,
            target = {
                coords = vec3(-478.38, -997.72, 34.34),
                label = 'Brankas',
                icon = 'fas fa-archive',
                group = 'mechanic'
            }
        },
        ['brankas_mechanic'] = {
            label = 'Brankas Tikum Speed',
            slots = 200,
            weight = 1000000,
            jobs = 'mechanic',
            withdraw_grade = 1,
            deposit_grade = 0,
            target = {
                coords = vec3(-926.75, -2025.5, 14.45),
                label = 'Brankas',
                icon = 'fas fa-archive',
                group = 'mechanic'
            }
        }
    }
}

local serverStash = {}
for id, data in pairs(Cfg.Stash) do
    serverStash[id] = {
        label = data.label,
        slots = data.slots,
        weight = data.weight,
        jobs = data.jobs,
        withdraw_grade = data.withdraw_grade,
        deposit_grade = data.deposit_grade
    }
end

local clientStash = {}
for id, data in pairs(Cfg.Stash) do
    clientStash[id] = {
        target = data.target
    }
end

return {
    Stash = IsDuplicityVersion() and serverStash or clientStash
}