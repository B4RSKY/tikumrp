fx_version "cerulean"
game "gta5"
author 'FutureSeekerTech'
description 'FS Guard Private Edition'
lua54 'yes'
version '1.2.0'

client_scripts {
    'module/cl_module.obfuscated.lua',
    'cl_guard.lua',
}

server_scripts {
    'config.lua',
    'module/tokensys_module.obfuscated.lua',
    'module/whitelist_module.obfuscated.lua',
    'module/ban_module.obfuscated.lua',
    'module/invenprotect_module.obfuscated.lua',
    'module/playeraction_module.lua',
    'module/sv_module.obfuscated.lua',
    'sv_guard.lua',
	'@oxmysql/lib/MySQL.lua',
}

dependencies {
    'oxmysql',
}