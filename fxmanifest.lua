fx_version 'cerulean'
game 'gta5'

author 'R tachibana'
description 'RPlimitspeed allows you to set speed limits for your own vehicle.'

client_script {
    'client.lua',
}

shared_script {
    'locales/*.lua', 
}

files {
    'locales/en.lua', 
    'locales/jp.lua', 
}

data_files {
    ['locales'] = 'locales/*', 
}
