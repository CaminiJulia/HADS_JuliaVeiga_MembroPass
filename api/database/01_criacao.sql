-- MembroPass — Criação das tabelas
-- Cada papel tem um cadastro de acesso independente (DVP v2.6).

CREATE TYPE status_organizacao AS ENUM ('EM_HABILITACAO', 'HABILITADA', 'SUSPENSA');
CREATE TYPE status_cadastro AS ENUM ('ATIVO', 'INATIVO');
CREATE TYPE status_membro AS ENUM ('ATIVO', 'DESATIVADO', 'CANCELADO');
CREATE TYPE tipo_desconto AS ENUM ('PERCENTUAL', 'VALOR');
CREATE TYPE status_carteirinha AS ENUM ('ATIVA', 'BLOQUEADA', 'INVALIDADA');
CREATE TYPE tipo_unidade_evento AS ENUM ('UNIDADE', 'EVENTO');
CREATE TYPE acao_auditoria AS ENUM (
    'LIBERACAO_CICLO', 'BLOQUEIO_MANUAL', 'DESBLOQUEIO',
    'DESATIVACAO_MEMBRO', 'REATIVACAO_MEMBRO', 'EDICAO_PLANO'
);

-- RF03 e RF17: a organização e a identidade visual aplicada a todas as carteirinhas.
CREATE TABLE organizacao (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome           VARCHAR(150) NOT NULL,
    cnpj           CHAR(14) NOT NULL UNIQUE,
    status         status_organizacao NOT NULL DEFAULT 'EM_HABILITACAO',
    cor_principal  CHAR(7) CHECK (cor_principal ~ '^#[0-9A-F]{6}$'),
    -- Segunda cor do degradê; NULL usa uma versão escura da principal.
    cor_secundaria CHAR(7) CHECK (cor_secundaria ~ '^#[0-9A-F]{6}$'),
    estilo_fundo   VARCHAR(10) NOT NULL DEFAULT 'DEGRADE'
                   CHECK (estilo_fundo IN ('DEGRADE', 'SOLIDO', 'PADRAO')),
    modelo_carteirinha VARCHAR(12) NOT NULL DEFAULT 'CLASSICO'
                   CHECK (modelo_carteirinha IN ('CLASSICO', 'MODERNO', 'MINIMALISTA')),
    logo           BYTEA CHECK (octet_length(logo) <= 524288),
    logo_tipo      VARCHAR(20) CHECK (logo_tipo IN ('image/png', 'image/jpeg')),
    CHECK ((logo IS NULL) = (logo_tipo IS NULL))
);

CREATE TABLE administrador (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacao_id  UUID NOT NULL REFERENCES organizacao (id),
    nome            VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    senha_hash      VARCHAR(255) NOT NULL,
    status          status_cadastro NOT NULL DEFAULT 'ATIVO'
);

CREATE TABLE operador (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacao_id  UUID NOT NULL REFERENCES organizacao (id),
    nome            VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    senha_hash      VARCHAR(255) NOT NULL,
    status          status_cadastro NOT NULL DEFAULT 'ATIVO'
);

-- RF04: planos de associação. Desativar um plano não afeta os membros já vinculados.
CREATE TABLE plano_associacao (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacao_id    UUID NOT NULL REFERENCES organizacao (id),
    nome              VARCHAR(100) NOT NULL,
    valor_referencia  NUMERIC(10, 2) NOT NULL CHECK (valor_referencia >= 0),
    duracao_dias      INTEGER NOT NULL CHECK (duracao_dias > 0),
    -- Cor de identificação do plano no app (#RRGGBB); NULL usa a cor padrão.
    cor               CHAR(7) CHECK (cor ~ '^#[0-9A-F]{6}$'),
    status            status_cadastro NOT NULL DEFAULT 'ATIVO'
);

-- Nome do plano único dentro da organização.
CREATE UNIQUE INDEX plano_associacao_nome_un ON plano_associacao (organizacao_id, lower(nome));

-- RF06: membros da organização. Todo membro pertence a um plano.
CREATE TABLE membro (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacao_id  UUID NOT NULL REFERENCES organizacao (id),
    nome            VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    senha_hash      VARCHAR(255) NOT NULL,
    telefone        VARCHAR(20),
    plano_id        UUID NOT NULL REFERENCES plano_associacao (id),
    data_adesao     DATE NOT NULL DEFAULT CURRENT_DATE,
    status          status_membro NOT NULL DEFAULT 'ATIVO'
);

-- RF05: carteirinha digital, uma por membro. A versão do QR muda a cada
-- liberação ou bloqueio, invalidando QR Codes antigos.
CREATE TABLE carteirinha (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    membro_id        UUID NOT NULL UNIQUE REFERENCES membro (id),
    qr_versao        INTEGER NOT NULL DEFAULT 1,
    data_emissao     DATE NOT NULL DEFAULT CURRENT_DATE,
    data_vencimento  DATE NOT NULL,
    status           status_carteirinha NOT NULL DEFAULT 'ATIVA'
);

-- RF07: cada pagamento confirmado manualmente pelo administrador libera um novo ciclo.
CREATE TABLE liberacao_ciclo (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    membro_id            UUID NOT NULL REFERENCES membro (id),
    confirmado_por       UUID NOT NULL REFERENCES administrador (id),
    data_pagamento       DATE NOT NULL,
    data_confirmacao     TIMESTAMPTZ NOT NULL DEFAULT now(),
    vencimento_anterior  DATE NOT NULL,
    novo_vencimento      DATE NOT NULL,
    valor_referencia     NUMERIC(10, 2) NOT NULL
);

CREATE INDEX liberacao_ciclo_membro_idx ON liberacao_ciclo (membro_id);

-- RF16: registro imutável das ações sensíveis do administrador.
CREATE TABLE auditoria (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacao_id    UUID NOT NULL REFERENCES organizacao (id),
    administrador_id  UUID NOT NULL REFERENCES administrador (id),
    acao              acao_auditoria NOT NULL,
    entidade          VARCHAR(50) NOT NULL,
    entidade_id       UUID NOT NULL,
    descricao         TEXT NOT NULL,
    justificativa     TEXT,
    data_hora         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX auditoria_organizacao_data_idx ON auditoria (organizacao_id, data_hora DESC);
CREATE INDEX auditoria_entidade_idx ON auditoria (entidade_id);

-- RF08: benefícios oferecidos pela organização, com vigência opcional.
CREATE TABLE beneficio (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacao_id  UUID NOT NULL REFERENCES organizacao (id),
    nome            VARCHAR(100) NOT NULL,
    descricao       TEXT,
    parceiro        VARCHAR(150),
    tipo_desconto   tipo_desconto NOT NULL,
    valor_desconto  NUMERIC(10, 2) NOT NULL CHECK (valor_desconto > 0),
    vig_inicio      DATE,
    vig_fim         DATE,
    -- Logo do parceiro, exibido no cartão do benefício.
    logo            BYTEA CHECK (octet_length(logo) <= 262144),
    logo_tipo       VARCHAR(20) CHECK (logo_tipo IN ('image/png', 'image/jpeg')),
    CHECK ((logo IS NULL) = (logo_tipo IS NULL)),
    CHECK (tipo_desconto <> 'PERCENTUAL' OR valor_desconto <= 100),
    CHECK (vig_inicio IS NULL OR vig_fim IS NULL OR vig_fim >= vig_inicio)
);

-- Quais planos dão direito a cada benefício (N:M).
CREATE TABLE plano_beneficio (
    plano_id      UUID NOT NULL REFERENCES plano_associacao (id) ON DELETE CASCADE,
    beneficio_id  UUID NOT NULL REFERENCES beneficio (id) ON DELETE CASCADE,
    PRIMARY KEY (plano_id, beneficio_id)
);

-- RF11: locais fixos (unidades) e eventos com período, onde a carteirinha é aceita.
CREATE TABLE unidade_evento (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacao_id  UUID NOT NULL REFERENCES organizacao (id),
    nome            VARCHAR(150) NOT NULL,
    tipo            tipo_unidade_evento NOT NULL,
    localizacao     VARCHAR(255),
    data_inicio     DATE,
    data_fim        DATE,
    -- Foto do local ou banner do evento, exibida como capa do cartão.
    imagem          BYTEA CHECK (octet_length(imagem) <= 524288),
    imagem_tipo     VARCHAR(20) CHECK (imagem_tipo IN ('image/png', 'image/jpeg')),
    CHECK ((imagem IS NULL) = (imagem_tipo IS NULL)),
    -- Evento tem período; unidade não.
    CHECK (
        (tipo = 'EVENTO' AND data_inicio IS NOT NULL AND data_fim IS NOT NULL AND data_fim >= data_inicio)
        OR (tipo = 'UNIDADE' AND data_inicio IS NULL AND data_fim IS NULL)
    )
);

-- Quais planos são aceitos em cada unidade ou evento (N:M).
CREATE TABLE unidade_evento_plano (
    unidade_evento_id  UUID NOT NULL REFERENCES unidade_evento (id) ON DELETE CASCADE,
    plano_id           UUID NOT NULL REFERENCES plano_associacao (id) ON DELETE CASCADE,
    PRIMARY KEY (unidade_evento_id, plano_id)
);

-- E-mail único dentro de cada cadastro, sem diferenciar maiúsculas.
CREATE UNIQUE INDEX administrador_email_un ON administrador (lower(email));
CREATE UNIQUE INDEX operador_email_un ON operador (lower(email));
CREATE UNIQUE INDEX membro_email_un ON membro (lower(email));
