fx_version 'cerulean'
game 'gta5'

shared_scripts {
	'@ox_lib/init.lua',
    'config/config.lua',
	'config/functions.lua',
	'locales/locale.lua',
    'locales/translations/*.lua'
}

server_scripts {
	'server/server.lua',
	'config/svconfig.lua'
}

client_scripts {
	'@mka-lasers/client/client.lua',
	'client/client.lua'
}

lua54 'yes'
