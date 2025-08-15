local Config = require "config.config"

exports('addMessage', function(message)
    while not ConfigLoaded do
        Wait(0)
    end

    TriggerServerEvent('chat:server:sendMessage', {
        category = 'custom',
        message = message,
        isImage = false,
        mask = false,
    })
end)