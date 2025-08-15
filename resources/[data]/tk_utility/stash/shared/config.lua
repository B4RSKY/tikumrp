local Cfg = {
    Stash = {
        ['police_evidence'] = {
            label = 'Police Evidence Locker',
            slots = 200,
            weight = 1000000,
            withdraw_grade = 2,
            deposit_grade = 0,
            jobs = 'police',
            target = {
                coords = vec3(451.5, -993.1, 30.7),
                label = 'Open Evidence Locker',
                icon = 'fas fa-archive',
                group = 'police'
            }
        },
        ['brankas_polisi'] = {
            label = 'Brankas Polisi',
            slots = 200,
            weight = 1000000,
            jobs = 'police',
            withdraw_grade = 0,
            deposit_grade = 0,
            target = false
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