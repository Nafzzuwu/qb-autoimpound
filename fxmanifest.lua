--Dont Change Anything In This Code!!--

fx_version 'cerulean'
game 'gta5'

author 'Nafzz'
description 'Auto Impound System - With Countdown'
version 'v1.2 Release'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qb-core',
    'oxmysql',
}
