RegisterCommand('hudsettings', function()
    lib.registerContext({
        id = 'uisetting',
        title = 'TIKUM UI SETTINGS',
        options = {
            {
                title = 'HUD STATUS',
                description = 'Untuk setting Bar Darah, Makan, Jobs, Spedo Meter',
                onSelect = function()
                    ExecuteCommand('statushudsettings')
                end
            }, {
                title = 'MENU LIB',
                description = 'Untuk Setting Tema Menu, Notifikasi, DSB',
                onSelect = function()
                    ExecuteCommand('ox_lib')
                end
            }
        }
    })
    lib.showContext('uisetting')
end)