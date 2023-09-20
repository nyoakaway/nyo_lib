fx_version   'cerulean'
game 'gta5'
lua54        'yes'


dependencies {
	'/server:5848',
    '/onesync',
}

shared_scripts { 
    'nyo_lib.lua',
    'lib/registerModules/shared.lua',
    'lib/eventsCallback/shared.lua',
    'lib/**/shared/**/*.lua',    
    'config/**/*.lua',     
    'scripts/**/config.lua',
}

server_scripts { 
    'lib/server.lua', 
    'framework/**/server.lua', 
    'lib/**/server.lua', 
    'lib/**/server/**/*.lua',
    'scripts/**/server.lua', 
    'scripts/**/server/**/*.lua'
 }

client_scripts { 
    'lib/client.lua', 
    'framework/**/client.lua', 
    'lib/**/client.lua',
    'lib/**/client/**/*.lua',
    'scripts/**/client.lua',
    'scripts/**/client/**/*.lua'
}


ui_page 'web/index.html'
files { 
    'web/*', 
    'web/**/*', 
    'scripts/**/web/**/*', 
    'scripts/**/lang/*'
}

