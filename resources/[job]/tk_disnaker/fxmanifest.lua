fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	--'@fs-guard/guard.lua',
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
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