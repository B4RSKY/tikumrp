fx_version 'cerulean'
game 'gta5'
author 'TheIrham'

ui_page "nui/ui.html"
version '1.1.4'

lua54 'yes'

shared_script '@ox_lib/init.lua'

shared_scripts {
	"config.lua",
	'shared/*.lua',
	"lang/*.lua",
	"@fmid_utils/functions/loader.lua",
}

client_scripts {
	-- '@fmid_ikanv2_np/client/minigame.lua', -- nyalakan ini jika menggunakan DLC fmid_ikanv2_np
	"client.lua",
	"client-fishing.lua",
}

server_scripts {
	"@mysql-async/lib/MySQL.lua",
	"server.lua",
}

files {
	"nui/lang/*",
	"nui/ui.html",
	"nui/panel.js",
	"nui/css/*",
	"nui/images/*",
	"nui/images/**",
}

dependency "fmid_utils"