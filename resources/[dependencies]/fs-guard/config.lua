DebugMode = false -- Enable debug mode (true/false)

InvenProtect = {}
InvenProtect.Enable = false -- Enable InvenProtect (true/false)
InvenProtect.Framework = "qb" -- esx or qb
InvenProtect.List = {
    ["stashjobpolice"] = {
        id = "stashjobpolice",
        type = "distance", -- distance or job
        validatorValue = vector(158.71873474121095, 6639.66845703125, 31.11751365661621), -- vector3
    },
    ["stashjobambulance"] = {
        id = "stashjobambulance",
        type = "job", -- distance or job
        validatorValue = "ambulance", -- jobname
    }
}