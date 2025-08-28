fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tk_vip'
author 'TK'
version '1.1.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

client_scripts {
    'client/client.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

-- Exports
client_export 'getVip'
client_export 'getVipJenis'
server_export 'getVip'
server_export 'getVipJenis'