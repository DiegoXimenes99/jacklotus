Config = {}

-- Debug mode (mostra prints no console)
Config.Debug = true

-- Sistema de banco de dados
Config.UseMySQL = true -- Ativa persistência de dados

-- Configurações gerais (valores padrão - podem ser alterados no banco)
Config.MinNumber = 1 -- Número mínimo que pode ser escolhido
Config.MaxNumber = 999 -- Número máximo que pode ser escolhido
Config.EntryPrice = 5000 -- Preço para entrar na loteria
Config.ServerPoolAmount = 10000 -- Valor que o servidor adiciona ao prêmio inicial

-- Tempo para o sorteio (em minutos) - pode ser alterado no banco
Config.DrawTime = 3 -- Tempo até o próximo sorteio

-- Auto-save (salvar prêmio a cada X segundos)
Config.AutoSaveInterval = 60 -- Salva o prêmio a cada 60 segundos

-- Configurações do NPC
Config.UsePed = true -- Ativar/desativar o NPC

Config.Ped = {
    model = "a_m_m_business_01", -- Modelo do NPC
    coords = vector4(1112.86, 232.49, 80.99, 0.0), -- Posição e rotação do NPC
    scenario = "WORLD_HUMAN_CLIPBOARD" -- Animação do NPC (opcional)
}

-- Localização do blip no mapa e interação
Config.LotteryLocation = {
    coords = vector3(1112.86, 232.49, 80.99), -- Cassino (ajuste conforme necessário)
    heading = 0.0
}

-- Configurações do Blip
Config.Blip = {
    enabled = true,
    sprite = 500, -- dinheiro icone 
    color = 46, -- Cor amarela/dourada
    scale = 0.8,
    name = "Loteria",
    shortRange = true
}

-- Configurações do ox_target
Config.Target = {
    name = "lottery_interaction",
    icon = "fas fa-ticket",
    label = "Abrir Loteria",
    distance = 2.5
}

-- Notificações
Config.Notifications = {
    noMoney = "Você não tem dinheiro suficiente!",
    entrySuccess = "Você entrou na loteria com o número %s!",
    numberInvalid = "Número inválido! Escolha entre %s e %s.",
    alreadyEntered = "Você já está participando desta rodada!",
    winner = "🎉 PARABÉNS! Você ganhou R$%s na loteria!",
    noWinner = "Ninguém acertou o número %s! O prêmio acumulou para R$%s!",
    drawAnnouncement = "🎰 SORTEIO DA LOTERIA! Número sorteado: %s | Prêmio: R$%s"
}

-- Função de debug
function Config.DebugPrint(...)
    if Config.Debug then
        print("^3[LOTTERY DEBUG]^7", ...)
    end
end