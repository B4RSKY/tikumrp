fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua'
}

client_scripts {
	'@fs-guard/cl_guard.lua',
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'@fs-guard/sv_guard.lua',
	'server/*.lua'
}

ui_page 'style/index.html'

files {
    'style/index.html',
    'style/style.css',
    'style/main.js',
	'style/sound/*.wav',
	'style/images/*.png',
	'style/fonts/*.ttf',
}