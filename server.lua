-- QBox usa exports diretos, não GetCoreObject

-- Variáveis da loteria
local currentPrize = Config.ServerPoolAmount
local participants = {}
local drawTimer = Config.DrawTime * 60 * 1000
local isDrawing = false

Config.DebugPrint("Servidor iniciado - Prêmio inicial: R$" .. currentPrize)

-- Função para notificar
local function Notify(source, message, type)
    -- Usar notificação simples do QBCore/QBox
    TriggerClientEvent('QBCore:Notify', source, message, type or 'primary')
    Config.DebugPrint("Notificação enviada para jogador " .. source .. ": " .. message)
end

-- Função para notificar todos
local function NotifyAll(message)
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(245, 158, 11, 0.8); border-radius: 5px;"><b>🎰 LOTERIA:</b> {0}</div>',
        args = { message }
    })
    Config.DebugPrint("Notificação global: " .. message)
end

-- Função para remover dinheiro
local function RemoveMoney(source, amount)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then
        Config.DebugPrint("ERRO: Jogador não encontrado (ID: " .. source .. ")")
        return false
    end
    
    -- Tenta remover do dinheiro em mãos primeiro
    if Player.Functions.GetMoney('cash') >= amount then
        Player.Functions.RemoveMoney('cash', amount)
        Config.DebugPrint("Removido R$" .. amount .. " (cash) do jogador " .. source)
        return true
    -- Senão tenta do banco
    elseif Player.Functions.GetMoney('bank') >= amount then
        Player.Functions.RemoveMoney('bank', amount)
        Config.DebugPrint("Removido R$" .. amount .. " (bank) do jogador " .. source)
        return true
    end
    
    Config.DebugPrint("ERRO: Jogador " .. source .. " não tem dinheiro suficiente")
    return false
end

-- Função para adicionar dinheiro
local function AddMoney(source, amount)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then
        Config.DebugPrint("ERRO: Jogador não encontrado para adicionar dinheiro (ID: " .. source .. ")")
        return
    end
    
    Player.Functions.AddMoney('cash', amount)
    Config.DebugPrint("Adicionado R$" .. amount .. " ao jogador " .. source)
end

-- Pegar nome do jogador
local function GetPlayerName(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then
        Config.DebugPrint("ERRO: Jogador não encontrado para pegar nome (ID: " .. source .. ")")
        return "Desconhecido"
    end
    
    local name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    Config.DebugPrint("Nome do jogador " .. source .. ": " .. name)
    return name
end

-- Realizar sorteio
local function PerformDraw()
    if isDrawing then 
        Config.DebugPrint("Sorteio já está em andamento, ignorando...")
        return 
    end
    
    isDrawing = true
    Config.DebugPrint("=== INICIANDO SORTEIO ===")
    Config.DebugPrint("Participantes: " .. json.encode(participants))
    
    local winningNumber = math.random(Config.MinNumber, Config.MaxNumber)
    Config.DebugPrint("Número sorteado: " .. winningNumber)
    
    local winner = nil
    
    -- Procurar vencedor
    for source, number in pairs(participants) do
        Config.DebugPrint("Verificando jogador " .. source .. " com número " .. number)
        if number == winningNumber then
            winner = source
            Config.DebugPrint("VENCEDOR ENCONTRADO! Jogador: " .. source)
            break
        end
    end
    
    if winner then
        -- Tem vencedor
        local winnerName = GetPlayerName(winner)
        AddMoney(winner, currentPrize)
        
        Notify(winner, string.format(Config.Notifications.winner, currentPrize), 'success')
        NotifyAll(string.format("🎉 %s ganhou R$%s acertando o número %s!", winnerName, currentPrize, winningNumber))
        
        Config.DebugPrint("Prêmio de R$" .. currentPrize .. " entregue ao vencedor")
        
        -- Resetar prêmio
        currentPrize = Config.ServerPoolAmount
    else
        -- Ninguém ganhou - acumula
        Config.DebugPrint("Nenhum vencedor! Prêmio acumula para: R$" .. currentPrize)
        NotifyAll(string.format(Config.Notifications.noWinner, winningNumber, currentPrize))
    end
    
    -- Limpar participantes
    participants = {}
    isDrawing = false
    
    Config.DebugPrint("=== SORTEIO FINALIZADO ===")
    Config.DebugPrint("Novo prêmio: R$" .. currentPrize)
    
    -- Atualizar todos os clientes
    TriggerClientEvent('lottery:updatePrize', -1, currentPrize)
    
    -- Agendar próximo sorteio
    Config.DebugPrint("Próximo sorteio em " .. Config.DrawTime .. " minutos")
    SetTimeout(drawTimer, PerformDraw)
end

-- Iniciar timer do sorteio
SetTimeout(drawTimer, PerformDraw)
Config.DebugPrint("Timer de sorteio iniciado: " .. Config.DrawTime .. " minutos")

-- Entrar na loteria
RegisterNetEvent('lottery:enter', function(chosenNumber)
    local source = source
    Config.DebugPrint("Jogador " .. source .. " tentando entrar com número: " .. tostring(chosenNumber))
    
    -- Validar número
    if chosenNumber < Config.MinNumber or chosenNumber > Config.MaxNumber then
        Config.DebugPrint("ERRO: Número inválido - " .. tostring(chosenNumber))
        Notify(source, string.format(Config.Notifications.numberInvalid, Config.MinNumber, Config.MaxNumber), 'error')
        return
    end
    
    -- Verificar se já está participando
    if participants[source] then
        Config.DebugPrint("ERRO: Jogador " .. source .. " já está participando")
        Notify(source, Config.Notifications.alreadyEntered, 'error')
        return
    end
    
    -- Remover dinheiro
    if not RemoveMoney(source, Config.EntryPrice) then
        Notify(source, Config.Notifications.noMoney, 'error')
        return
    end
    
    -- Adicionar ao prêmio
    currentPrize = currentPrize + Config.EntryPrice
    Config.DebugPrint("Prêmio atualizado: R$" .. currentPrize)
    
    -- Registrar participante
    participants[source] = chosenNumber
    Config.DebugPrint("Participante registrado: " .. source .. " = número " .. chosenNumber)
    
    -- Notificar
    local playerName = GetPlayerName(source)
    Notify(source, string.format(Config.Notifications.entrySuccess, chosenNumber), 'success')
    NotifyAll(string.format("💰 %s entrou na loteria! Prêmio atual: R$%s", playerName, currentPrize))
    
    -- Atualizar todos os clientes
    TriggerClientEvent('lottery:updatePrize', -1, currentPrize)
end)

-- Enviar informações para o cliente
RegisterNetEvent('lottery:requestInfo', function()
    local source = source
    Config.DebugPrint("Jogador " .. source .. " solicitou informações")
    
    TriggerClientEvent('lottery:receiveInfo', source, {
        prize = currentPrize,
        minNumber = Config.MinNumber,
        maxNumber = Config.MaxNumber,
        entryPrice = Config.EntryPrice
    })
end)

-- Remover participante ao desconectar
AddEventHandler('playerDropped', function(reason)
    local source = source
    if participants[source] then
        Config.DebugPrint("Jogador " .. source .. " desconectou e foi removido dos participantes")
        participants[source] = nil
    end
end)

Config.DebugPrint("=== SISTEMA DE LOTERIA CARREGADO ===")
Config.DebugPrint("Prêmio inicial: R$" .. currentPrize)
Config.DebugPrint("Intervalo de números: " .. Config.MinNumber .. " - " .. Config.MaxNumber)
Config.DebugPrint("Preço de entrada: R$" .. Config.EntryPrice)