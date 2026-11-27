-- =====================================================================
-- PROJETO INTEGRADOR: SABOR & CLIC
-- Arquivo: 11_queries_relatorios.sql
-- Objetivo: Consultas para relatorios de vendas, pratos, estoque e bancadas.
-- Execute depois dos arquivos 01 e 02.
-- =====================================================================

USE sabor_clic;

-- 1. RELATORIO GERAL DE VENDAS
-- Mostra quantidade de pedidos, faturamento e ticket medio.
SELECT
    COUNT(DISTINCT p.id) AS quantidade_pedidos,
    COALESCE(SUM(ip.quantidade * ip.preco_unitario), 0) AS faturamento_total,
    COALESCE(
        SUM(ip.quantidade * ip.preco_unitario) /
        NULLIF(COUNT(DISTINCT p.id), 0), 0
    ) AS ticket_medio
FROM pedidos p
LEFT JOIN itens_pedido ip ON ip.pedido_id = p.id
WHERE p.status <> 'Cancelado';

-- 2. PRATOS MAIS VENDIDOS
SELECT
    pr.id,
    pr.nome AS prato,
    COALESCE(SUM(CASE WHEN p.id IS NOT NULL THEN ip.quantidade ELSE 0 END), 0)
        AS quantidade_vendida,
    COALESCE(SUM(CASE WHEN p.id IS NOT NULL
        THEN ip.quantidade * ip.preco_unitario ELSE 0 END), 0) AS valor_vendido
FROM pratos pr
LEFT JOIN itens_pedido ip ON ip.prato_id = pr.id
LEFT JOIN pedidos p
    ON p.id = ip.pedido_id
   AND p.status <> 'Cancelado'
GROUP BY pr.id, pr.nome
ORDER BY quantidade_vendida DESC, pr.nome;

-- 3. RELATORIO DE ESTOQUE
SELECT
    id,
    nome_item,
    quantidade_atual,
    unidade_medida,
    CASE
        WHEN quantidade_atual = 0 THEN 'Sem estoque'
        WHEN quantidade_atual <= 5 THEN 'Estoque baixo'
        ELSE 'Estoque adequado'
    END AS situacao
FROM estoque
ORDER BY quantidade_atual ASC, nome_item;

-- 4. INGREDIENTES UTILIZADOS NA FICHA TECNICA
SELECT
    pr.nome AS prato,
    e.nome_item AS ingrediente,
    ft.quantidade_necessaria AS quantidade_por_prato,
    e.unidade_medida
FROM ficha_tecnica ft
JOIN pratos pr ON pr.id = ft.prato_id
JOIN estoque e ON e.id = ft.estoque_id
ORDER BY pr.nome, e.nome_item;

-- 5. PEDIDOS POR STATUS
SELECT
    status,
    COUNT(*) AS quantidade
FROM pedidos
GROUP BY status
ORDER BY quantidade DESC;

-- 6. HISTORICO DE PEDIDOS DOS CLIENTES
SELECT
    p.id AS pedido,
    u.nome AS cliente,
    p.data_pedido,
    p.status,
    COALESCE(SUM(ip.quantidade * ip.preco_unitario), 0) AS total
FROM pedidos p
JOIN usuarios u ON u.id = p.cliente_id
LEFT JOIN itens_pedido ip ON ip.pedido_id = p.id
GROUP BY p.id, u.nome, p.data_pedido, p.status
ORDER BY p.data_pedido DESC;

-- 7. OCUPACAO / AGENDAMENTOS DAS BANCADAS
SELECT
    b.id,
    b.nome AS bancada,
    COUNT(a.id) AS total_agendamentos,
    SUM(CASE WHEN a.status = 'confirmado' THEN 1 ELSE 0 END) AS confirmados,
    SUM(CASE WHEN a.status = 'pendente' THEN 1 ELSE 0 END) AS pendentes
FROM bancadas b
LEFT JOIN agendamentos_bancadas a ON a.bancada_id = b.id
GROUP BY b.id, b.nome
ORDER BY b.nome;

-- 8. VALOR ESTIMADO DOS AGENDAMENTOS CONFIRMADOS
-- O valor e calculado pela duracao em horas multiplicada pelo valor/hora.
SELECT
    a.id AS agendamento,
    b.nome AS bancada,
    u.nome AS cliente,
    a.data_inicio,
    a.data_fim,
    ROUND(
        TIMESTAMPDIFF(MINUTE, a.data_inicio, a.data_fim) / 60
        * b.valor_hora, 2
    ) AS valor_estimado
FROM agendamentos_bancadas a
JOIN bancadas b ON b.id = a.bancada_id
JOIN usuarios u ON u.id = a.cliente_id
WHERE a.status = 'confirmado'
ORDER BY a.data_inicio;

-- 9. FATURAMENTO POR PRATO
SELECT
    pr.nome AS prato,
    SUM(ip.quantidade) AS unidades_vendidas,
    SUM(ip.quantidade * ip.preco_unitario) AS faturamento
FROM itens_pedido ip
JOIN pratos pr ON pr.id = ip.prato_id
JOIN pedidos p ON p.id = ip.pedido_id
WHERE p.status <> 'Cancelado'
GROUP BY pr.id, pr.nome
ORDER BY faturamento DESC;


-- 10. SEGURANCA: DEMONSTRACAO DE AES_ENCRYPT() E AES_DECRYPT()
-- Use a mesma chave informada no arquivo 02_insercoes_basicas.sql.
-- A chave abaixo e didatica; em producao, nao deixe chaves no script.
SET @chave_aes = 'CHAVE_DEMO_TROCAR_2026';

-- Consulta o conteudo criptografado armazenado no banco (formato hexadecimal).
SELECT
    id,
    nome,
    HEX(endereco) AS endereco_criptografado
FROM usuarios
WHERE id = 2;

-- Descriptografa o endereco para uma consulta autorizada.
SELECT
    id,
    nome,
    CAST(AES_DECRYPT(endereco, @chave_aes) AS CHAR(255) CHARACTER SET utf8mb4)
        AS endereco_descriptografado
FROM usuarios
WHERE id = 2;

-- IMPORTANTE:
-- AES_ENCRYPT() e AES_DECRYPT() precisam usar a mesma chave.
-- Senhas nao devem ser descriptografadas: use hash de senha no backend.
-- Nao armazene a chave real junto com os dados criptografados em producao.
