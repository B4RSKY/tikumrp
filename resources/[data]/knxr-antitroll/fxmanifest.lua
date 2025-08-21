fx_version "cerulean"
games { "gta5" }
lua54 "yes"

ui_page "ui/ui.html"

client_scripts {
    "client/cl_main.lua"
}

shared_scripts {
    '@ox_lib/init.lua',
    "config.lua"
}

files {
    "ui/ui.html",
    "ui/js/app.js",
    "ui/css/app.css",
}


server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/sv_functions.lua",
    "server/sv_main.lua",
}