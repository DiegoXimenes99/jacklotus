-- =====================================================
-- SISTEMA DE LOTERIA - TABELAS MYSQL
-- =====================================================

-- Tabela de configurações da loteria
CREATE TABLE IF NOT EXISTS `lottery_settings` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `min_number` INT(11) NOT NULL DEFAULT 1,
    `max_number` INT(11) NOT NULL DEFAULT 100,
    `entry_price` INT(11) NOT NULL DEFAULT 5000,
    `draw_time` INT(11) NOT NULL DEFAULT 30,
    `current_prize` INT(11) NOT NULL DEFAULT 10000,
    `last_updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Inserir configurações padrão
INSERT INTO `lottery_settings` (`id`, `min_number`, `max_number`, `entry_price`, `draw_time`, `current_prize`) 
VALUES (1, 1, 100, 5000, 30, 10000)
ON DUPLICATE KEY UPDATE id=id;

-- Tabela de histórico de sorteios
CREATE TABLE IF NOT EXISTS `lottery_history` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `winning_number` INT(11) NOT NULL,
    `winner_identifier` VARCHAR(50) DEFAULT NULL,
    `winner_name` VARCHAR(100) DEFAULT NULL,
    `prize_amount` INT(11) NOT NULL,
    `has_winner` TINYINT(1) NOT NULL DEFAULT 0,
    `draw_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `draw_date` (`draw_date`),
    KEY `winner_identifier` (`winner_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- QUERIES ÚTEIS PARA ADMINISTRAÇÃO
-- =====================================================

-- Ver configurações atuais
-- SELECT * FROM lottery_settings;

-- Alterar número mínimo e máximo
-- UPDATE lottery_settings SET min_number = 1, max_number = 100 WHERE id = 1;

-- Alterar preço de entrada
-- UPDATE lottery_settings SET entry_price = 10000 WHERE id = 1;

-- Alterar tempo entre sorteios (em minutos)
-- UPDATE lottery_settings SET draw_time = 60 WHERE id = 1;

-- Alterar prêmio acumulado
-- UPDATE lottery_settings SET current_prize = 50000 WHERE id = 1;

-- Ver histórico de sorteios (últimos 10)
-- SELECT * FROM lottery_history ORDER BY draw_date DESC LIMIT 10;

-- Ver todos os ganhadores
-- SELECT * FROM lottery_history WHERE has_winner = 1 ORDER BY draw_date DESC;

-- Ver sorteios sem ganhador (acumulados)
-- SELECT * FROM lottery_history WHERE has_winner = 0 ORDER BY draw_date DESC;

-- Ver total de dinheiro distribuído
-- SELECT SUM(prize_amount) as total_distribuido FROM lottery_history WHERE has_winner = 1;

-- Ver quantidade de sorteios realizados
-- SELECT COUNT(*) as total_sorteios FROM lottery_history;

-- Limpar histórico (CUIDADO!)
-- TRUNCATE TABLE lottery_history;