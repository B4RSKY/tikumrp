fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'loop.lua',
    '**/shared/*.lua'
}

client_scripts {
    '**/client/*.lua',
    'keybinds.lua'
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '**/server/*.lua',
}

ui_page 'vipsystem/html/index.html'

files {
    'vipsystem/html/index.html',
    'vipsystem/html/style.css',
    'vipsystem/html/app.js',
}