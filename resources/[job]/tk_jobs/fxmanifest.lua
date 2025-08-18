fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '**/shared/*.lua'
}

client_scripts {
    '**/client/*.lua',
}
server_scripts {
    '**/server/*.lua',
}

data_file "DLC_ITYP_REQUEST" "stream/cuffs_main.ytyp"