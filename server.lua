-- QBox usa exports diretos, não GetCoreObject
local currentPrize = Config.ServerPoolAmount
local participants = {}
local isDrawing = false

-- Inicialização do MySQL
local function InitDatabase()
    if not Config.UseMySQL then return end
    
    -- Carregar configurações e prêmio do banco
    MySQL.single('SELECT * FROM lottery_settings WHERE id = 1', {}, function(result)
        if result then
            Config.MinNumber = result.min_number
            Config.MaxNumber = result.max_number
            Config.EntryPrice = result.entry_price
            Config.DrawTime = result.draw_time
            currentPrize = result.current_prize
            Config.DebugPrint("Configurações carregadas do Banco de Dados.")
            Config.DebugPrint("Prêmio Atual: R$" .. currentPrize)
        else
            -- Criar entrada padrão se não existir
            MySQL.insert('INSERT INTO lottery_settings (id, min_number, max_number, entry_price, draw_time, current_prize) VALUES (?, ?, ?, ?, ?, ?)',
                {1, Config.MinNumber, Config.MaxNumber, Config.EntryPrice, Config.DrawTime, Config.ServerPoolAmount})
            Config.DebugPrint("Configurações padrão inseridas no Banco de Dados.")
        end
    end)
end

-- Salvar prêmio atual no banco
local function SavePrize()
    if not Config.UseMySQL then return end
    MySQL.update('UPDATE lottery_settings SET current_prize = ? WHERE id = 1', {currentPrize}, function(affectedRows)
        if affectedRows > 0 then
            Config.DebugPrint("Prêmio salvo no Banco de Dados: R$" .. currentPrize)
        end
    end)
end

-- Notificação simples do QBox
local function Notify(source, message, type)
    TriggerClientEvent('QBCore:Notify', source, message, type or 'primary')
end

-- Notificação global via Chat
local function NotifyAll(message)
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(245, 158, 11, 0.8); border-radius: 5px; color: white; font-family: sans-serif;"><b>🎰 LOTERIA:</b> {0}</div>',
        args = { message }
    })
end

-- Função para remover dinheiro (Cash ou Bank)
local function RemoveMoney(source, amount)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false end
    
    if Player.Functions.GetMoney('cash') >= amount then
        Player.Functions.RemoveMoney('cash', amount)
        return true
    elseif Player.Functions.GetMoney('bank') >= amount then
        Player.Functions.RemoveMoney('bank', amount)
        return true
    end
    return false
end

-- Pegar nome do personagem
local function GetPlayerName(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return "Desconhecido" end
    return Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
end

-- Obter Identificador (CitizenID)
local function GetPlayerIdentifier(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

-- Realizar o Sorteio
local function PerformDraw()
    if isDrawing then return end
    isDrawing = true
    
    Config.DebugPrint("=== INICIANDO SORTEIO ===")
    
    local winningNumber = math.random(Config.MinNumber, Config.MaxNumber)
    local winners = {} -- Lista de IDs dos vencedores
    
    -- Identificar todos os vencedores (Suporte a múltiplos vencedores)
    for src, num in pairs(participants) do
        if num == winningNumber then
            table.insert(winners, src)
        end
    end
    
    if #winners > 0 then
        -- Dividir prêmio se houver mais de um vencedor
        local prizePerWinner = math.floor(currentPrize / #winners)
        local winnersNames = {}
        
        for _, src in ipairs(winners) do
            local Player = exports.qbx_core:GetPlayer(src)
            if Player then
                Player.Functions.AddMoney('bank', prizePerWinner)
                local name = GetPlayerName(src)
                table.insert(winnersNames, name)
                
                Notify(src, string.format(Config.Notifications.winner, prizePerWinner), 'success')
                
                -- Logar histórico de cada vencedor
                if Config.UseMySQL then
                    MySQL.insert('INSERT INTO lottery_history (winning_number, winner_identifier, winner_name, prize_amount, has_winner) VALUES (?, ?, ?, ?, ?)',
                        {winningNumber, GetPlayerIdentifier(src), name, prizePerWinner, 1})
                end
            end
        end
        
        local announcement = string.format("🎉 %s acertaram o número %s e dividiram R$%s!", table.concat(winnersNames, ", "), winningNumber, currentPrize)
        NotifyAll(announcement)
        
        -- Resetar prêmio para o valor inicial do servidor
        currentPrize = Config.ServerPoolAmount
    else
        -- Ninguém ganhou - acumula
        NotifyAll(string.format(Config.Notifications.noWinner, winningNumber, currentPrize))
        
        -- Logar sorteio sem vencedor
        if Config.UseMySQL then
            MySQL.insert('INSERT INTO lottery_history (winning_number, prize_amount, has_winner) VALUES (?, ?, ?)',
                {winningNumber, currentPrize, 0})
        end
    end
    
    -- Limpar participantes para a próxima rodada
    participants = {}
    isDrawing = false
    SavePrize() -- Salvar estado após o sorteio
    
    TriggerClientEvent('lottery:updatePrize', -1, currentPrize)
    SetTimeout(Config.DrawTime * 60 * 1000, PerformDraw)
end

-- Eventos de Rede
RegisterNetEvent('lottery:enter', function(chosenNumber)
    local src = source
    
    -- Proteção contra exploits: verificar se é número inteiro e válido
    if type(chosenNumber) ~= "number" or chosenNumber % 1 ~= 0 then
        Notify(src, "Número inválido detectado!", 'error')
        return
    end

    if chosenNumber < Config.MinNumber or chosenNumber > Config.MaxNumber then
        Notify(src, string.format(Config.Notifications.numberInvalid, Config.MinNumber, Config.MaxNumber), 'error')
        return
    end
    
    if participants[src] then
        Notify(src, Config.Notifications.alreadyEntered, 'error')
        return
    end
    
    -- Tentar cobrar entrada
    if not RemoveMoney(src, Config.EntryPrice) then
        Notify(src, Config.Notifications.noMoney, 'error')
        return
    end
    
    -- Sucesso na entrada
    currentPrize = currentPrize + Config.EntryPrice
    participants[src] = chosenNumber
    
    local playerName = GetPlayerName(src)
    Notify(src, string.format(Config.Notifications.entrySuccess, chosenNumber), 'success')
    NotifyAll(string.format("💰 %s entrou na loteria! Prêmio atual: R$%s", playerName, currentPrize))
    
    TriggerClientEvent('lottery:updatePrize', -1, currentPrize)
    SavePrize()
end)

RegisterNetEvent('lottery:requestInfo', function()
    local src = source
    TriggerClientEvent('lottery:receiveInfo', src, {
        prize = currentPrize,
        minNumber = Config.MinNumber,
        maxNumber = Config.MaxNumber,
        entryPrice = Config.EntryPrice
    })
end)

-- Limpeza ao desconectar
AddEventHandler('playerDropped', function()
    local src = source
    if participants[src] then
        participants[src] = nil
    end
end)

-- Inicialização do recurso
MySQL.ready(function()
    InitDatabase()
    -- Iniciar primeiro ciclo de sorteio
    SetTimeout(Config.DrawTime * 60 * 1000, PerformDraw)
end)

-- Loop de Auto-Save (Opcional, já salvamos em eventos críticos)
CreateThread(function()
    while true do
        Wait(Config.AutoSaveInterval * 1000)
        SavePrize()
    end
end)

Config.DebugPrint("=== SISTEMA DE LOTERIA CARREGADO COM MYSQL ===")