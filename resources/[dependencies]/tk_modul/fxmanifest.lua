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
    '**/server/*.lua',
}