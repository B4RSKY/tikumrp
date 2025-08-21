fx_version 'cerulean'
game 'gta5'
lua54 'yes'

files {
    'locales/*.json',
    'modules/framework/**/client.lua',
    'modules/target/*.lua',
    'modules/utils/client.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locales.lua'
}

client_scripts {
    'client/cl_main.lua'
}

server_scripts {
    'server/sv_main.lua'
}
