-- =====================================================================
-- PROJETO INTEGRADOR: SABOR & CLIC
-- Arquivo opcional: 03_teste_triggers.sql
-- Objetivo: Criar pedidos de demonstracao e testar a baixa automatica.
-- Execute depois de 01_modelo_fisico.sql, 02_insercoes_basicas.sql
-- e 20_triggers.sql.
-- =====================================================================

USE sabor_clic;

-- Cria um pedido para a cliente Ana (usuario ID 2).
INSERT INTO pedidos (cliente_id, status, tempo_estimado)
VALUES (2, 'Aguardando', 30);

-- Ao inserir o item, a trigger desconta os ingredientes da ficha tecnica.
-- Este exemplo consome 2 porcoes de Nhoque:
-- Batata: 0,600 kg; Farinha: 0,200 kg; Molho: 0,300 litro.
INSERT INTO itens_pedido (pedido_id, prato_id, quantidade, preco_unitario)
VALUES (1, 1, 2, 32.50);

-- Consulte o estoque depois da insercao.
SELECT id, nome_item, quantidade_atual, unidade_medida
FROM estoque
ORDER BY nome_item;

-- Teste de relatorio: total do pedido.
SELECT
    p.id AS pedido,
    u.nome AS cliente,
    SUM(ip.quantidade * ip.preco_unitario) AS total_pedido
FROM pedidos p
JOIN usuarios u ON u.id = p.cliente_id
JOIN itens_pedido ip ON ip.pedido_id = p.id
WHERE p.id = 1
GROUP BY p.id, u.nome;
