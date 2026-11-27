-- =====================================================================
-- PROJETO INTEGRADOR: SABOR & CLIC
-- Arquivo: 20_triggers.sql
-- Objetivo: Automatizar a baixa e a reposicao dos ingredientes.
-- Banco utilizado: MySQL 8.0.16 ou superior
--
-- REGRA:
-- INSERT em itens_pedido: desconta ingredientes do estoque.
-- UPDATE da quantidade: ajusta a diferenca no estoque.
-- DELETE de itens_pedido: devolve os ingredientes ao estoque.
--
-- Importante: cada item do pedido representa uma porcao do prato.
-- A ficha_tecnica informa quanto de cada ingrediente e usado por porcao.
-- =====================================================================

USE sabor_clic;

DELIMITER $$

-- 1. ANTES DE INSERIR: valida prato, quantidade e disponibilidade de estoque.
CREATE TRIGGER trg_itens_bi_validar_estoque
BEFORE INSERT ON itens_pedido
FOR EACH ROW
BEGIN
    DECLARE v_faltas INT DEFAULT 0;
    DECLARE v_prato_ativo BOOLEAN DEFAULT FALSE;

    IF NEW.quantidade <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A quantidade do item deve ser maior que zero.';
    END IF;

    SELECT COALESCE(MAX(ativo), FALSE)
      INTO v_prato_ativo
      FROM pratos
     WHERE id = NEW.prato_id;

    IF v_prato_ativo = FALSE THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'O prato nao existe ou esta inativo.';
    END IF;

    SELECT COUNT(*)
      INTO v_faltas
      FROM ficha_tecnica ft
      JOIN estoque e ON e.id = ft.estoque_id
     WHERE ft.prato_id = NEW.prato_id
       AND e.quantidade_atual < (ft.quantidade_necessaria * NEW.quantidade);

    IF v_faltas > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estoque insuficiente para preparar este prato.';
    END IF;
END$$

-- 2. DEPOIS DE INSERIR: desconta os ingredientes do estoque.
CREATE TRIGGER trg_itens_ai_baixar_estoque
AFTER INSERT ON itens_pedido
FOR EACH ROW
BEGIN
    UPDATE estoque e
    JOIN ficha_tecnica ft ON ft.estoque_id = e.id
       SET e.quantidade_atual =
           e.quantidade_atual - (ft.quantidade_necessaria * NEW.quantidade)
     WHERE ft.prato_id = NEW.prato_id;
END$$

-- 3. ANTES DE ATUALIZAR: impede trocar o prato/pedido e valida aumento de quantidade.
CREATE TRIGGER trg_itens_bu_validar_estoque
BEFORE UPDATE ON itens_pedido
FOR EACH ROW
BEGIN
    DECLARE v_faltas INT DEFAULT 0;

    IF NEW.pedido_id <> OLD.pedido_id OR NEW.prato_id <> OLD.prato_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Para trocar o prato ou pedido, remova o item e insira novamente.';
    END IF;

    IF NEW.quantidade <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A quantidade do item deve ser maior que zero.';
    END IF;

    IF NEW.quantidade > OLD.quantidade THEN
        SELECT COUNT(*)
          INTO v_faltas
          FROM ficha_tecnica ft
          JOIN estoque e ON e.id = ft.estoque_id
         WHERE ft.prato_id = OLD.prato_id
           AND e.quantidade_atual <
               (ft.quantidade_necessaria * (NEW.quantidade - OLD.quantidade));

        IF v_faltas > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Estoque insuficiente para aumentar a quantidade.';
        END IF;
    END IF;
END$$

-- 4. DEPOIS DE ATUALIZAR: ajusta o estoque pela diferenca de quantidade.
CREATE TRIGGER trg_itens_au_ajustar_estoque
AFTER UPDATE ON itens_pedido
FOR EACH ROW
BEGIN
    UPDATE estoque e
    JOIN ficha_tecnica ft ON ft.estoque_id = e.id
       SET e.quantidade_atual =
           e.quantidade_atual -
           (ft.quantidade_necessaria * (NEW.quantidade - OLD.quantidade))
     WHERE ft.prato_id = NEW.prato_id;
END$$

-- 5. DEPOIS DE EXCLUIR: devolve os ingredientes ao estoque.
CREATE TRIGGER trg_itens_ad_repor_estoque
AFTER DELETE ON itens_pedido
FOR EACH ROW
BEGIN
    UPDATE estoque e
    JOIN ficha_tecnica ft ON ft.estoque_id = e.id
       SET e.quantidade_atual =
           e.quantidade_atual + (ft.quantidade_necessaria * OLD.quantidade)
     WHERE ft.prato_id = OLD.prato_id;
END$$

DELIMITER ;

-- FIM DAS TRIGGERS
