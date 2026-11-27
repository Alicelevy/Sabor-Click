-- =====================================================================
-- PROJETO INTEGRADOR: SABOR & CLIC
-- Arquivo: 02_insercoes_basicas.sql
-- Objetivo: Inserir dados iniciais para testar o sistema.
-- Execute depois do arquivo 01_modelo_fisico.sql.
-- =====================================================================

USE sabor_clic;

-- CHAVE DIDATICA: substitua por uma chave forte e mantenha-a fora do codigo
-- em uma aplicacao real. Esta chave serve somente para demonstracao em aula.
SET @chave_aes = 'CHAVE_DEMO_TROCAR_2026';

-- 1. USUARIOS
-- O endereco da cliente Ana e criptografado antes de ser gravado.
-- Senhas ficticias para ambiente academico/teste.
-- Em uma aplicacao real, armazene hashes de senha, nunca texto puro.
INSERT INTO usuarios (nome, email, senha, tipo, endereco, turno, especialidade) VALUES
('Carlos Gestor', 'admin@saborclic.com', 'HASH_DE_TESTE_ADMIN', 'administrador', NULL, NULL, NULL),
('Ana Cliente', 'ana@email.com', 'HASH_DE_TESTE_CLIENTE', 'cliente', AES_ENCRYPT('Avenida Paulista, 500 - Ap 42', @chave_aes), NULL, NULL),
('Bruno Cozinheiro', 'bruno.chef@saborclic.com', 'HASH_DE_TESTE_COZINHEIRO', 'cozinheiro', NULL, 'Manha', 'Massas e Molhos');

-- 2. PRATOS
INSERT INTO pratos (nome, descricao, preco, ativo, admin_id) VALUES
('Nhoque Artesanal ao Sugo', 'Nhoque fresco de batata com molho de tomate rustico e manjericao.', 32.50, TRUE, 1),
('Hamburguer Artesanal Sabor & Clic', 'Blend de carne, queijo cheddar e molho da casa.', 28.90, TRUE, 1),
('Risoto de Cogumelos', 'Arroz arboreo com cogumelos frescos e parmesao.', 45.00, TRUE, 1);

-- 3. BANCADAS
INSERT INTO bancadas (nome, descricao, valor_hora, disponivel) VALUES
('Bancada Profissional 1 - Confeitaria', 'Batedeira planetaria, forno industrial e bancada em inox.', 50.00, TRUE),
('Bancada Profissional 2 - Fogao Quente', 'Fogao, fritadeira e exaustor.', 65.00, TRUE),
('Bancada de Montagem de Pratos', 'Espaco para finalizacao de embalagens e delivery.', 35.00, TRUE);

-- 4. INGREDIENTES DO ESTOQUE
INSERT INTO estoque (nome_item, quantidade_atual, unidade_medida) VALUES
('Batata', 50.000, 'kg'),
('Farinha de Trigo', 30.000, 'kg'),
('Molho de Tomate', 20.000, 'litros'),
('Carne Bovina', 15.000, 'kg'),
('Queijo Cheddar', 10.000, 'kg'),
('Arroz Arboreo', 12.000, 'kg'),
('Cogumelos Frescos', 5.000, 'kg');

-- 5. FICHAS TECNICAS
-- As quantidades representam o consumo de ingrediente para UM prato.
INSERT INTO ficha_tecnica (prato_id, estoque_id, quantidade_necessaria) VALUES
-- Nhoque: batata, farinha e molho
(1, 1, 0.300),
(1, 2, 0.100),
(1, 3, 0.150),
-- Hamburguer: carne e cheddar
(2, 4, 0.180),
(2, 5, 0.050),
-- Risoto: arroz e cogumelos
(3, 6, 0.200),
(3, 7, 0.080);

-- 6. AGENDAMENTO DE EXEMPLO
INSERT INTO agendamentos_bancadas
    (bancada_id, cliente_id, data_inicio, data_fim, status)
VALUES
    (1, 2, '2026-12-10 09:00:00', '2026-12-10 12:00:00', 'confirmado');

-- Os pedidos de demonstracao estao no arquivo 03_teste_triggers.sql,
-- que deve ser executado somente depois de criar as triggers.
