fx_version 'cerulean'
game 'gta5'

author '.crutchie'
description 'qbx_rentals. This script took insperation from qb-rentals by Carbon#1002 and g-bikerentals by Giana'
version '0.0.1'


shared_scripts {
    '@ox_lib/init.lua',
	'@qbx_core/modules/lib.lua',
    '@qbx_core/modules/playerdata.lua',
}

client_script {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/ComboZone.lua',
    'client/*.lua'
}

server_script {
    'server/*.lua'
}

files {
	'config/client.lua',
	'config/server.lua'
}

dependencies {
	'ox_lib',
	'ox_target',
	'ox_inventory',
	'qbx_core',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'