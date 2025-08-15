local Config = require 'proses.shared.config'

local zones = {}
local isProcessing = false

local function addZones()
    for _, p in ipairs(Config.Proses) do
        local opts = {}
        for rIndex, r in ipairs(p.resep or {}) do
            opts[#opts+1] = {
                name = ('proses_%s_%d'):format(p.id, rIndex),
                label = r.label or ('Proses: %s → %s'):format(r.input, r.output),
                icon = 'fa-solid fa-flask',
                distance = p.radius + 0.3,
                onSelect = function()
                    if isProcessing then return end
                    local resp = lib.callback.await('tk-illegal:proses:mulai', false, p.id, rIndex)
                    if not resp or not resp.ok then
                        lib.notify({ title = 'Proses', description = (resp and resp.msg) or 'Gagal mulai.', type = 'error' })
                        return
                    end
                    isProcessing = true
                    local duration = resp.duration or (p.duration or 5000)

                    local cancelled = not lib.progressCircle({
                        duration = duration,
                        position = 'bottom',
                        label = r.label or ('Memproses %s...'):format(r.input),
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, car = true, mouse = false, combat = true },
                        anim = p.anim and { dict = p.anim.dict, clip = p.anim.clip, flag = p.anim.flag } or nil,
                        scenario = p.scenario
                    })

                    ClearPedTasks(PlayerPedId())

                    if cancelled then
                        TriggerServerEvent('tk-illegal:proses:cancel')
                        isProcessing = false
                        lib.notify({ title = 'Proses', description = 'Dibatalkan.', type = 'warning' })
                        return
                    end

                    TriggerServerEvent('tk-illegal:proses:selesai')
                end
            }
        end

        local zoneId = exports.ox_target:addSphereZone({
            coords = p.coords,
            radius = p.radius,
            debug = false,
            drawSprite = false,
            options = opts
        })
        zones[p.id] = zoneId
    end
end

local function removeZones()
    for id, z in pairs(zones) do
        exports.ox_target:removeZone(z)
        zones[id] = nil
    end
end

RegisterNetEvent('tk-illegal:proses:don', function(ok, msg)
    isProcessing = false
    if ok then
        lib.notify({ title = 'Proses', description = msg or 'Berhasil.', type = 'success' })
    else
        lib.notify({ title = 'Proses', description = msg or 'Gagal.', type = 'error' })
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    addZones()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    removeZones()
end)

CreateThread(addZones)