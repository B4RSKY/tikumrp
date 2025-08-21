Config = {}
local QBCore = exports['qb-core']:GetCoreObject()
Config.OpenRadial = { hold = true }
Config.MaxItems = { enable = true, max = 8 }
Config.ItemRadial = {
    {
        id = 'radial:phone',
        label = 'Phone',
        icon = "mobile-alt",
        canEnable = function()
            return not IsEntityDead(PlayerPedId())
        end,    
        action = function ()
            exports["lb-phone"]:ToggleOpen(true, false)
        end
    },
    {
        id = 'radial:inventory',
        label = 'Inventory',
        icon = "briefcase",
        canEnable = function()
            return not IsEntityDead(PlayerPedId())
        end,
        event = "ox_inventory:openInventory"
    },
    {
        id = 'radial:dokumen',
        label = 'Dokumen',
        icon = "file",
        canEnable = function()
            return not IsEntityDead(PlayerPedId())
        end,
        command = "documents"
    },
    {
        id = 'radial:billiingg',
        label = 'Billing',
        icon = "money-bill",
        canEnable = function()
            return not IsEntityDead(PlayerPedId())
        end,
        command = "bills"
    },
    {
        id = 'radial:kunci',
        label = 'Kunci',
        icon = "key",
        canEnable = function()
            if (IsPedInAnyVehicle(cache.ped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(cache.ped, false), -1) == cache.ped) then
                return true
            else
                local dist = lib.getClosestVehicle(GetEntityCoords(cache.ped), 2.5)
                if dist then
                    return true
                end
            end
        end,
        event = "tk-kunci:client:togglelocks"
    },
    {
        id = "radial:carmenu",
        label = "Kendaraan",
        icon = "vehicle",
        canEnable = function()
            return (IsPedInAnyVehicle(PlayerPedId(), false))
        end,
        event = "vehcontrol:client:openMenu"
    },
    {
        id = 'radial:policejob',
        label = 'Polisi',
        icon = "shield-alt",
        KeepOpen = false,
        canEnable = function ()
            local hasJob = exports.tk_disnaker:hasJob("police")
            return hasJob
        end,
        options = {
            {
                id = "polisi:emergencybutton",
                icon = "shield-alt",
                label = "Emergency button",
                event = "police:client:SendPoliceEmergencyAlert"
            },
            {
                id = "polisi:mdt",
                icon = "mobile-alt",
                label = "MDT",
                command = "mdt"
            },
            {
                id = "polisi:borgol",
                icon = "handcuffs",
                label = "Borgol/lepas",
                event = "police:client:CuffPlayerSoft"
            },
            {
                id = "polisi:cekid",
                icon = "address-card",
                label = "Revoke Drivers License",
                event = "police:client:SeizeDriverLicense"
            },
            {
                id = "polisi:seret",
                icon = "shield-alt",
                label = "Seret",
                event = "tk-job:seret"
            },
            {
                id = "polisi:seret2",
                icon = "shield-alt",
                label = "Seret 2",
                event = "police:client:KidnapPlayer"
            },
            {
                id = "polisi:putinveh",
                icon = "car-side",
                label = "Masukkan Kendaraan",
                event = "police:client:PutPlayerInVehicle"
            },
            {
                id = "polisi:outveh",
                icon = "car-side",
                label = "Keluarkan Dari Kendaraan",
                event = "police:client:SetPlayerOutVehicle"
            },
            {
                id = "polisi:geledah",
                icon = "shield-alt",
                label = "Geledah",
                action = function ()
                    local myCoords = GetEntityCoords(cache.ped)
                    local player = lib.getClosestPlayer(myCoords)

                    if not player then
                        ESX.ShowNotification("Tidak ada orang di sekitar", "error", 8000)
                        return
                    end

                    TriggerServerEvent('tk-job:message', GetPlayerServerId(player), 'Anda sedang digeledah!')
                    exports.ox_inventory:openNearbyInventory()
                end
            },
            {
                id = "polisi:penjara",
                icon = "user-lock",
                label = "Penjara",
                event = "police:client:JailPlayer"
            },
            {
                id = "polisi:sita",
                icon = "car-side",
                label = "Impound Kendaraan",
                event = "wasabi_police:impoundVehicle"
            },
            {
                id = "polisi:checkstatus",
                icon = "car-side",
                label = "Check status",
                event = "police:client:CheckStatus"
            },
            {
                id = "polisi:billplayer",
                icon = "money-bill",
                label = "Billing Warga",
                event = "peleg-billing:client:invOpen"
            },
        }
    },
        {
        id = 'radial:policeObjek',
        label = 'Object',
        icon = "road",
        KeepOpen = false,
        canEnable = function ()
            return exports.tk_disnaker:hasJob("police")
        end,
        options = {
            {
                id = "polisi:obj:cone",
                icon = "road",
                label = "Cone",
                event = "police:client:spawnCone"
            }, {
                id = "polisi:obj:gate",
                icon = "road",
                label = "Gate",
                event = "police:client:spawnBarrier"
            }, {
                id = "polisi:obj:roadsign",
                icon = "road",
                label = "Speed Limit Sign",
                event = "police:client:spawnRoadSign"
            }, {
                id = "polisi:obj:spikestrip",
                icon = "road",
                label = "Spike Strips",
                event = "police:client:SpawnSpikeStrip"
            },{
                id = "polisi:obj:deleteobject",
                icon = "road",
                label = "Remove object",
                event = "police:client:deleteObject"
            },
        }
    },
    {
        id = 'radial:emsjob',
        label = 'Medis',
        icon = "user-doctor",
        KeepOpen = false,
        canEnable = function()
            return exports.tk_disnaker:hasJob("ambulance")
        end,
        options = {
            {
                id = "ems:healthcek",
                icon = "kit-medical",
                label = "Check Health Status",
                event = "hospital:client:CheckStatus"
            },
            {
                id = "ems:billplayer",
                icon = "money-bill",
                label = "Billing Warga",
                event = "peleg-billing:client:invOpen"
            },
            {
                id = "ems:revive",
                icon = "kit-medical",
                label = "Revive",
                event = "hospital:client:RevivePlayer"
            },
            {
                id = "ems:obati",
                icon = "bandage",
                label = "Treatment",
                event = "hospital:client:TreatWounds"
            },
            {
                id = "ems:masukkan",
                icon = "car-side",
                label = "Masukkan Paksa",
                event = "police:client:PutPlayerInVehicle"
            },
            {
                id = "ems:tokno",
                icon = "car-side",
                label = "Keluarkan Paksa",
                event = "police:client:SetPlayerOutVehicle"
            },
            {
                id = "ems:seret",
                icon = "shield-alt",
                label = "Seret",
                event = "tk-job:seret"
            },
            {
                id = "ems:mdt",
                icon = "mobile-alt",
                label = "MDT",
                command = "mdt"
            },
        }
    },
    {
        id = 'radial:mechanicjob',
        label = 'Mekanik',
        icon = "user-gear",
        KeepOpen = false,
        canEnable = function()
            return exports.tk_disnaker:hasJob("mechanic")
        end,
        options = {
            {
                id = "mech:repair",
                icon = "wrench",
                label = "Repair Full",
                event = "qb-mechanicjob:client:repairVehicleFull"
            },
            {
                id = "mech:billplayer",
                icon = "money-bill",
                label = "Billing Warga",
                event = "peleg-billing:client:invOpen"
            },
            {
                id = "mech:hijack",
                icon = "gear",
                label = "Bobol",
                event = "tk-job:bobol"
            },
            {
                id = "mech:tow",
                icon = "truck-pickup",
                label = "Towing",
                event = "tk-job:towcok"
            },
            {
                id = "mech:clean",
                icon = "soap",
                label = "Cuci",
                event = "qb-mechanicjob:client:cleanVehicle"
            },
        }
    },
    {
        id = 'radial:badside',
        label = 'Job',
        icon = "shield-alt",
        KeepOpen = false,
        canEnable = function()
            local Data = QBCore.Functions.GetPlayerData()
            return (Data.gang.name == 'vagos')
        end,
        options = {
            {
                id = "polisi:borgol",
                icon = "handcuffs",
                label = "Borgol/lepas",
                event = "police:client:CuffPlayerSoft"
            },
            {
                id = "job:geledah",
                icon = "magnifying-glass",
                label = "Geledah",
                action = function ()
                    local myCoords = GetEntityCoords(cache.ped)
                    local closestPlayerId = lib.getClosestPlayer(myCoords, 2.5, false)

                    if closestPlayerId then
                        local targetServerId = GetPlayerServerId(closestPlayerId)

                        if targetServerId ~= -1 then
                            QBCore.Functions.Notify("Geledah", "Anda mulai menggeledah pemain di dekat Anda...", "info")
                            TriggerServerEvent('tk-job:server:notifyTarget', targetServerId, 'Anda sedang digeledah oleh seseorang!')
                            exports.ox_inventory:openNearbyInventory()
                        else
                            QBCore.Functions.Notify("Geledah", "Target tidak valid.", "error")
                        end
                    else
                        QBCore.Functions.Notify("Geledah", "Tidak ada pemain di dekat Anda untuk digeledah.", "error")
                    end
                end
            },
            {
                id = "job:seret",
                icon = "user-secret",
                label = "Seret",
                event = "tk-job:seret"
            },
            {
                id = "job:masuk",
                icon = "user-secret",
                label = "Masukkan",
                event = "police:client:PutPlayerInVehicle"
            },
            {
                id = "job:metu",
                icon = "user-secret",
                label = "keluarkan",
                event = "police:client:SetPlayerOutVehicle"
            },
        }
    },
}