fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tk_exit_dui'
author 'TK'
version '1.1.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

files {
    'web/**',
}

-- DUI memakai lib.dui atau fallback native
dependencies { 'ox_lib' }
