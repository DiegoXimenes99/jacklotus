-- QBox não usa GetCoreObject, usa sistema modular
-- QBX.PlayerData é fornecido pelo módulo playerdata.lua
local nuiOpen = false
local lotteryPed = nil

Config.DebugPrint("Cliente iniciado")

-- Função para spawnar o ped
local function SpawnLotteryPed()
    if not Config.UsePed then 
        Config.DebugPrint("Spawn de NPC desabilitado na config")
        return 
    end
    
    local pedModel = Config.Ped.model
    local pedCoords = Config.Ped.coords
    
    Config.DebugPrint("Tentando spawnar NPC: " .. pedModel .. " em " .. tostring(pedCoords))
    
    local pedHash = GetHashKey(pedModel)
    
    -- Solicitar o modelo
    RequestModel(pedHash)
    local timeout = 0
    while not HasModelLoaded(pedHash) and timeout < 10000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(pedHash) then
        Config.DebugPrint("ERRO: Não foi possível carregar o modelo do NPC: " .. pedModel)
        return
    end
    
    Config.DebugPrint("Modelo carregado com sucesso: " .. pedModel)
    
    -- Criar o ped
    lotteryPed = CreatePed(4, pedHash, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, true)
    
    if not lotteryPed or lotteryPed == 0 then
        Config.DebugPrint("ERRO: Falha ao criar o NPC")
        return
    end
    
    Config.DebugPrint("NPC criado com ID: " .. tostring(lotteryPed))
    
    -- Configurar o ped
    SetEntityAsMissionEntity(lotteryPed, true, true)
    SetPedFleeAttributes(lotteryPed, 0, 0)
    SetPedDiesWhenInjured(lotteryPed, false)
    SetPedKeepTask(lotteryPed, true)
    SetBlockingOfNonTemporaryEvents(lotteryPed, true)
    SetEntityInvincible(lotteryPed, true)
    FreezeEntityPosition(lotteryPed, true)
    
    -- Aplicar cenário se especificado
    if Config.Ped.scenario then
        TaskStartScenarioInPlace(lotteryPed, Config.Ped.scenario, 0, true)
        Config.DebugPrint("Cenário aplicado: " .. Config.Ped.scenario)
    end
    
    Config.DebugPrint("Ped da loteria spawnou com sucesso!")
    
    -- Aguardar um pouco antes de adicionar o ox_target
    Wait(1000)
    
    -- Verificar se o ox_target está disponível
    if not exports['ox_target'] then
        Config.DebugPrint("ERRO: ox_target não está disponível!")
        return
    end
    
    -- Adicionar ox_target no ped
    local targetOptions = {
        {
            name = Config.Target.name,
            icon = Config.Target.icon,
            label = Config.Target.label,
            onSelect = function()
                Config.DebugPrint("ox_target: Jogador clicou no NPC da loteria")
                TriggerEvent('lottery:openUI')
            end,
            distance = Config.Target.distance
        }
    }
    
    exports['ox_target']:addLocalEntity(lotteryPed, targetOptions)
    Config.DebugPrint("ox_target adicionado ao ped da loteria com sucesso!")
    
    -- Liberar o modelo da memória
    SetModelAsNoLongerNeeded(pedHash)
end

-- Criar blip no mapa
CreateThread(function()
    if Config.Blip.enabled then
        local blipCoords = Config.Ped and Config.Ped.coords or Config.LotteryLocation.coords
        local blip = AddBlipForCoord(blipCoords.x, blipCoords.y, blipCoords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, Config.Blip.shortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.name)
        EndTextCommandSetBlipName(blip)
        
        Config.DebugPrint("Blip criado na localização: " .. tostring(blipCoords))
    end
end)

-- Spawnar ped quando o jogador estiver pronto
CreateThread(function()
    -- Aguardar o jogador estar totalmente carregado
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    Wait(2000) -- Aguardar um pouco mais antes de spawnar
    Config.DebugPrint("Iniciando spawn do NPC...")
    SpawnLotteryPed()
end)

-- Deletar ped ao sair
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if lotteryPed and DoesEntityExist(lotteryPed) then
        -- Remover ox_target antes de deletar
        if exports['ox_target'] then
            exports['ox_target']:removeLocalEntity(lotteryPed, Config.Target.name)
        end
        DeleteEntity(lotteryPed)
        Config.DebugPrint("Ped da loteria deletado")
    end
end)

-- Abrir NUI
RegisterNetEvent('lottery:openUI', function()
    if nuiOpen then 
        Config.DebugPrint("NUI já está aberta, ignorando...")
        return 
    end
    
    Config.DebugPrint("Abrindo NUI da loteria")
    
    -- Requisitar informações atualizadas
    TriggerServerEvent('lottery:requestInfo')
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open"
    })
    nuiOpen = true
end)

-- Receber informações do servidor
RegisterNetEvent('lottery:receiveInfo', function(data)
    Config.DebugPrint("Informações recebidas do servidor: " .. json.encode(data))
    SendNUIMessage({
        action = "updateInfo",
        data = data
    })
end)

-- Atualizar prêmio
RegisterNetEvent('lottery:updatePrize', function(prize)
    Config.DebugPrint("Prêmio atualizado para: R$" .. prize)
    SendNUIMessage({
        action = "updatePrize",
        prize = prize
    })
end)

-- Fechar NUI
RegisterNUICallback('close', function(data, cb)
    Config.DebugPrint("Fechando NUI")
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "close"
    })
    nuiOpen = false
    cb('ok')
end)

-- Entrar na loteria
RegisterNUICallback('enterLottery', function(data, cb)
    local number = tonumber(data.number)
    Config.DebugPrint("Tentando entrar na loteria com número: " .. tostring(number))
    
    if number then
        TriggerServerEvent('lottery:enter', number)
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = "close"
        })
        nuiOpen = false
    else
        Config.DebugPrint("ERRO: Número inválido recebido da NUI")
    end
    
    cb('ok')
end)

-- Fechar NUI com ESC
CreateThread(function()
    while true do
        Wait(0)
        if nuiOpen then
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 18, true) -- Enter
            DisableControlAction(0, 322, true) -- ESC
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            
            if IsControlJustPressed(0, 322) or IsControlJustPressed(0, 177) then -- ESC or BACKSPACE
            Config.DebugPrint("ESC pressionado, fechando NUI")
                SetNuiFocus(false, false)
                SendNUIMessage({
                    action = "close"
                })
                nuiOpen = false
            end
        else
            Wait(500)
        end
    end
end)

Config.DebugPrint("=== CLIENTE DE LOTERIA CARREGADO ===")