-- =====================================================================
-- PROJETO INTEGRADOR: SABOR & CLIC
-- Arquivo: 01_modelo_fisico.sql
-- Objetivo: Criar o banco de dados, tabelas, chaves e restricoes.
-- Banco utilizado: MySQL 8.0.16 ou superior
-- =====================================================================

DROP DATABASE IF EXISTS sabor_clic;
CREATE DATABASE sabor_clic
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE sabor_clic;

-- 1. USUARIOS: administradores, clientes e cozinheiros
-- O campo endereco armazena o resultado binario de AES_ENCRYPT().
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    tipo ENUM('administrador', 'cliente', 'cozinheiro') NOT NULL,
    endereco VARBINARY(512), -- Armazena o endereco criptografado com AES_ENCRYPT()
    turno VARCHAR(50),
    especialidade VARCHAR(100),
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_usuarios_tipo (tipo)
) ENGINE=InnoDB;

-- 2. PRATOS: itens disponibilizados no cardapio
CREATE TABLE pratos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10,2) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    admin_id INT NOT NULL,
    CONSTRAINT chk_pratos_preco CHECK (preco >= 0),
    CONSTRAINT fk_pratos_admin
        FOREIGN KEY (admin_id) REFERENCES usuarios(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_pratos_ativo (ativo),
    INDEX idx_pratos_nome (nome)
) ENGINE=InnoDB;

-- 3. BANCADAS: espacos gastronomicos disponiveis para locacao
CREATE TABLE bancadas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    valor_hora DECIMAL(10,2) NOT NULL,
    disponivel BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_bancadas_valor CHECK (valor_hora >= 0),
    INDEX idx_bancadas_disponivel (disponivel)
) ENGINE=InnoDB;

-- 4. AGENDAMENTOS DAS BANCADAS
CREATE TABLE agendamentos_bancadas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bancada_id INT NOT NULL,
    cliente_id INT NOT NULL,
    data_inicio DATETIME NOT NULL,
    data_fim DATETIME NOT NULL,
    status ENUM('pendente', 'confirmado', 'cancelado') NOT NULL DEFAULT 'pendente',
    CONSTRAINT chk_agendamento_periodo CHECK (data_fim > data_inicio),
    CONSTRAINT fk_agendamento_bancada
        FOREIGN KEY (bancada_id) REFERENCES bancadas(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_agendamento_cliente
        FOREIGN KEY (cliente_id) REFERENCES usuarios(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_agendamento_datas (data_inicio, data_fim),
    INDEX idx_agendamento_status (status)
) ENGINE=InnoDB;

-- 5. PEDIDOS: pedidos realizados pelos clientes
CREATE TABLE pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    status ENUM(
        'Aguardando',
        'Em Preparo',
        'Iniciando Preparo',
        'Pronto para Entrega',
        'Entregue',
        'Cancelado'
    ) NOT NULL DEFAULT 'Aguardando',
    tempo_estimado INT,
    data_pedido TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_pedido_tempo CHECK (tempo_estimado IS NULL OR tempo_estimado >= 0),
    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (cliente_id) REFERENCES usuarios(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_pedidos_status (status),
    INDEX idx_pedidos_data (data_pedido)
) ENGINE=InnoDB;

-- 6. ITENS DO PEDIDO: relacionamento entre pedidos e pratos
CREATE TABLE itens_pedido (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    prato_id INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_item_quantidade CHECK (quantidade > 0),
    CONSTRAINT chk_item_preco CHECK (preco_unitario >= 0),
    CONSTRAINT fk_item_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedidos(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_item_prato
        FOREIGN KEY (prato_id) REFERENCES pratos(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_pedido_prato UNIQUE (pedido_id, prato_id),
    INDEX idx_itens_prato (prato_id)
) ENGINE=InnoDB;

-- 7. ESTOQUE: ingredientes e suas quantidades disponiveis
CREATE TABLE estoque (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome_item VARCHAR(100) NOT NULL UNIQUE,
    quantidade_atual DECIMAL(10,3) NOT NULL,
    unidade_medida VARCHAR(20) NOT NULL,
    CONSTRAINT chk_estoque_quantidade CHECK (quantidade_atual >= 0)
) ENGINE=InnoDB;

-- 8. FICHA TECNICA: ingredientes e quantidade usada em cada prato
CREATE TABLE ficha_tecnica (
    id INT AUTO_INCREMENT PRIMARY KEY,
    prato_id INT NOT NULL,
    estoque_id INT NOT NULL,
    quantidade_necessaria DECIMAL(10,3) NOT NULL,
    CONSTRAINT chk_ficha_quantidade CHECK (quantidade_necessaria > 0),
    CONSTRAINT uq_ficha_prato_ingrediente UNIQUE (prato_id, estoque_id),
    CONSTRAINT fk_ficha_prato
        FOREIGN KEY (prato_id) REFERENCES pratos(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ficha_estoque
        FOREIGN KEY (estoque_id) REFERENCES estoque(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_ficha_estoque (estoque_id)
) ENGINE=InnoDB;

-- FIM DO MODELO FISICO
-- Observacao: as triggers ficam no arquivo 20_triggers.sql.
