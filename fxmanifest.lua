fx_version 'cerulean'
game 'gta5'

author 'Koki-Scripts'
description 'Jednoduchý fivem script na doručování balíků.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'server.lua'
}
