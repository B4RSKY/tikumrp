local Config = {}

Config.VipSystem = {
    VipJenis = {
        [1] = 'Bronze',
        [2] = 'Silver',
        [3] = 'Gold',
    },

    CodeLength = 10,
    CodeCharset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
    LockCodeToIdentifier = false,
    MaxDays = 365,

    SQL = {
        vipTable   = 'tk_vip',
        codesTable = 'tk_vip_codes',
        players    = 'players',
    },

    PageSize = 20,
}

if IsDuplicityVersion() then
    Config.VipSystem.AdminSteam = {
        'steam:11000013f5fbf6a',
    }
    Config.VipSystem.ExpiryWarnDays = 3
end

return Config