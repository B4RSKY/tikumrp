RegisterNetEvent('tk_utility:dg:mulai', function(emote)
    if source == '' then return end
    if not emote then return end
    ExecuteCommand('e c')
    ClearPedTasksImmediately(cache.ped)
    SetTimeout(500, function() ExecuteCommand('e '..emote) end)
end)

RegisterNetEvent('tk_utility:dg:stop', function()
    if source == '' then return end
    ExecuteCommand('e c')
    ClearPedTasksImmediately(cache.ped)
end)

RegisterCommand('emotegroup', function()
    lib.registerContext({
        id = 'dance_group',
        title = 'DANCE GROUP',
        options = {
            {
                title = 'Buat Sesi Dance',
                description = ' ',
                icon = 'person',
                onSelect = function()
                    ExecuteCommand('bsd')
                end
            },
            {
                title = 'Cek Sesi Dance',
                description = ' ',
                icon = 'check-to-slot',
                onSelect = function()
                    ExecuteCommand('csd')
                end
            },
            {
                title = 'Gabung Sesi Dance',
                description = ' ',
                icon = 'right-to-bracket',
                onSelect = function()
                    local input = lib.inputDialog('Gabung Sesi Dance', {'ID SESI:'})
                    if not input or not input[1] then return end
                    
                    local id = input[1]
                    ExecuteCommand('gsd ' .. id)
                end
            },
            {
                title = 'Mulai Emote',
                description = 'Bisa Menggunakan command "/msd emote" untuk mulai',
                icon = 'play',
                onSelect = function()
                    local input = lib.inputDialog('Mulai Memainkan Emote', {'NAMA EMOTE:'})
                    if not input or not input[1] then return end
                    
                    local emot = input[1]
                    ExecuteCommand('msd ' .. emot)
                end
            },
            {
                title = 'Stop Emote',
                description = 'Bisa Menggunakan command /ssd untuk berhenti',
                icon = 'pause',
                onSelect = function()
                    ExecuteCommand('ssd')
                end
            },
            {
                title = 'Keluar Sesi Dance',
                description = ' ',
                icon = 'x',
                onSelect = function()
                    ExecuteCommand('ksd')
                end
            },
        }
      })
      lib.showContext('dance_group')
end)