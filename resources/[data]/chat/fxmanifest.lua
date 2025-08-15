fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config/*.lua',
    'locales/*.lua',
    'utils/*.lua',
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/default.lua',
    'client/thread.lua',
    'client/commands.lua',
    'client/exports.lua',
    'modules/**/client.lua',
}

server_scripts {
    'server/*.lua',
    'modules/**/server.lua',
}

files {
    'web/build/*.*',
    'web/build/**/*.*',
    'locales/*.json',
}

ui_page 'web/build/index.html'
provide 'chat'