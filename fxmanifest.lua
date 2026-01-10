fx_version 'cerulean'
game 'gta5'

author 'Seu Nome'
description 'Sistema de Loteria com ox_target e NUI moderna'
version '1.0.0'

-- Dependências
dependencies {
    'qbx_core',
    'ox_target'
}

-- Shared
shared_script 'config.lua'

-- Scripts do servidor
server_scripts {
    'server.lua'
}

-- Scripts do cliente
client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client.lua'
}

-- NUI
ui_page 'html/index.html'

files {
    'html/index.html'
}

-- Versão do Lua
lua54 'yes'