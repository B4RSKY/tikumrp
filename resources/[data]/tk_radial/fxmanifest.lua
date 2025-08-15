fx_version "cerulean"
game "gta5"
lua54 "yes"

ui_page "html/ui.html"

shared_scripts {
	"@ox_lib/init.lua"
}

client_scripts {
	"config.lua",
	"client/*.lua",
}

files {
	"html/ui.html",
	"html/css/rm.css",
	"html/js/rm.js",
}