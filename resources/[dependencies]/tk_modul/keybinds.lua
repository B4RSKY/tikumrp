local shouldExecuteBind = true
AddEventHandler("tk-modul:shouldExecuteBind", function(status)
    shouldExecuteBind = status
end)

exports('registerKeyMapping', function(description, onKeyDownCommand, onKeyUpCommand, default, event, name)
	local type = "keyboard"
	if not name then name = "" end
	if not default then default = "" end
	cmdStringDown = "+cmd_wrapper__" .. onKeyDownCommand
    cmdStringUp = "-cmd_wrapper__" .. onKeyDownCommand
    RegisterCommand(cmdStringDown, function()
  		if not shouldExecuteBind then return end
  		if event then TriggerEvent(name) end
  		ExecuteCommand(onKeyDownCommand)
    end, false)    
    RegisterCommand(cmdStringUp, function()
      if not shouldExecuteBind then return end
      if event then TriggerEvent(name) end
      ExecuteCommand(onKeyUpCommand)
    end, false)
    RegisterKeyMapping(cmdStringDown, description, type, default)
end)

CreateThread(function()
    RegisterKeyMapping('+isKunci', 'Kunci kendaraan', 'keyboard', 'U')
    RegisterKeyMapping('+isshowIDPlayer', 'Show ID Players', 'keyboard', 'U')
    RegisterKeyMapping("oprenradial", "Radial Menu", "keyboard", 'F1')
    RegisterKeyMapping("+tk_bb_place", "Boombox: letakkan di tanah", "keyboard", 'G')
    RegisterKeyMapping("+tk_bb_store", "Boombox: Masukkan Tas", "keyboard", 'K')
end)