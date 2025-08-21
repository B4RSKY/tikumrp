Made by Lionh34rt
Discord: https://discord.gg/AWyTUEnGeN
Tebex: https://lionh34rt.tebex.io/

# Dependencies
* [mkalasers by mkafrin](https://github.com/mkafrin/mka-lasers)
* [Extended Pacific Bank by K4MB1 MAPS](https://k4mb1.tebex.io/package/4692112)
* [Memorygame by pushkart2](https://github.com/pushkart2/memorygame)
* [powerplant by Lionh34rt](https://lionh34rt.tebex.io/)

# Installation
* **Add the items to your shared > items.lua**
* **Install all the dependencies**
* **Create nightvision in smallresources**
* **Remove all bankrobbery related doorlocks in your doorlock script**
* **You may have to change the clothing piece in the nightvision.lua**
* **If using Gabz fleeca banks: you have to remove the default trolly entitysets**

# Nightvision: add this to your qb-smallresources
```lua
-- Server side:
QBCore.Functions.CreateUseableItem("nightvision", function(source)
    TriggerClientEvent("nightvision:UseNightvision", source)
end)

-- Client Side: create nightvision.lua
local QBCore = exports['qb-core']:GetCoreObject()

local nightvision = false

RegisterNetEvent("nightvision:UseNightvision", function()
    nightvision = not nightvision
    QBCore.Functions.Progressbar("remove_gear", "Nightvision..", 250, false, true, {}, {}, {}, {}, function()
        if nightvision then
            SetNightvision(true)
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "nv", 0.25)
            SetPedPropIndex(PlayerPedId(), 0, 117, 0, true)
        else
            SetNightvision(false)
            SetPedPropIndex(PlayerPedId(), 0, 116, 0, true)
        end
    end)
end)
```