RegisterNetEvent('chat:show', function()
    if not ConfigLoaded then return end

    SetNuiFocus(true, true)
    SendVueMessage('SHOW_CHAT', {})
    TriggerServerEvent('chat:server:writingText', true)
end)


RegisterNetEvent("chat:addSuggestion")
AddEventHandler("chat:addSuggestion", function(command, help, params)
    local suggestion = {
        name = string.gsub(command, "/", ""),
        help = help,
    }

    SendVueMessage("ADD_SUGGESTION", suggestion)
end)

RegisterNetEvent("chat:addSuggestions")
AddEventHandler("chat:addSuggestions", function(suggestions)
    for k, v in ipairs(suggestions) do
        local suggestion = {
            name = string.gsub(v.name, "/", ""),
            help = v.help,
        }

        SendVueMessage("ADD_SUGGESTION", suggestion)
    end
end)

RegisterNetEvent('__cfx_internal:serverPrint')
AddEventHandler('__cfx_internal:serverPrint', function(msg)
  print(msg)
end)