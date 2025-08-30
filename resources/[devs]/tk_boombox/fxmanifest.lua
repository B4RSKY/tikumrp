fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'Boombox / Music Box'
author '@barssky_'
description 'Boombox dengan fitur carry, local volume, saved songs, YT search'

shared_script '@ox_lib/init.lua'

client_scripts {
  'config/clconfig.lua',
  'client/main.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'config/svconfig.lua',
  'server/main.lua'
}