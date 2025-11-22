fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Evidence System'
author 'Xavi'
version '1.0.0'

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'ox_mysql'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}