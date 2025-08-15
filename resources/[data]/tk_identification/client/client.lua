LocalPlayer.state:set('idshown',false,false)
LocalPlayer.state:set('idvisible',false,false)

exports('identification', function(data, slot)
	if not LocalPlayer.state.idshown  then 
		exports.ox_inventory:useItem(data, function(data)
			if data then
				TriggerEvent('tk-identification:showID',data)
			end
		end)
	else
        lib.notify({title = 'License sedang cooldown.', type = 'error'})
	end
end)

RegisterNetEvent('tk-identification:showID', function(item)
	if not LocalPlayer.state.idshown  then 
		local playersInArea = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 2.5)
		if #playersInArea > 0 then 
			local Playerinareaid = {}
			for i = 1, #playersInArea do
				table.insert(Playerinareaid, GetPlayerServerId(playersInArea[i].id))
			end
			TriggerServerEvent('tk-identification:server:showID',item,Playerinareaid)
			TriggerEvent('tk-identification:openID',item)
		end

		LocalPlayer.state:set('idshown',true,false)
		TriggerEvent('tk-identification:openID',item)
		CreateThread(function()
			Wait(15 * 1000)
			LocalPlayer.state:set('idshown',false,false)
		end)
	end 
end)

RegisterNetEvent('tk-identification:openID', function(item)
	if LocalPlayer.state.idvisible == nil or not LocalPlayer.state.idvisible then 
		TriggerEvent('tk-identification:showUI',item)
	end 
end)

RegisterNetEvent('tk-identification:showUI', function(data)
	LocalPlayer.state:set('idvisible',true,false)
	SendNUIMessage({
		action = "open",
		metadata = data.metadata
	})
	RegisterCommand('cancel', function()
		SendNUIMessage({
			action = "close"
		})
		LocalPlayer.state:set('idvisible',false,false)
		RegisterCommand('cancel', function()
			-- empty the command
		end)
	end)
end)

RegisterCommand('closeidentification',function()
	SendNUIMessage({
		action = "close"
	})
	LocalPlayer.state:set('idvisible',false,false)
end)

RegisterKeyMapping('closeidentification', 'Close KTP', 'keyboard', 'BACK')