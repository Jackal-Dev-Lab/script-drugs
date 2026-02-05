fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'drug_production'
author 'Jackal'
description 'Gang-based drug production with lab control, intrusion and advanced crafting pipelines (no selling)'
version '1.0.0'

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql',
    't1ger_gangs'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/zones.lua',
    'client/labs.lua',
    'client/processing.lua',
    'client/effects.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/security.lua',
    'server/gangs.lua',
    'server/labs.lua',
    'server/production.lua'
}
