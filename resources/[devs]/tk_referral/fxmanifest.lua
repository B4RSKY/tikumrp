fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tk_referral'
author 'Putra + ChatGPT'
description 'Referral code with 60-min active play requirement (test set to 1 minute)'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql',
    'ox_inventory'
}
