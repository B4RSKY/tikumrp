fx_version 'cerulean'
lua54 'yes'
game 'gta5'

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua',
	'shared/init.lua',
}

client_script 'client.lua'
server_script 'server.lua'

ui_page 'ui/build/index.html'

files {
	'data/*.lua',
	'locales/*.json',
	'modules/**/client.lua',
	'modules/bridge/**/client.lua',
	'ui/build/index.html',
	'ui/build/**/*',
}