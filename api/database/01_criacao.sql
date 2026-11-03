-- MembroPass — Criação das tabelas (autenticação RF01/RF02 e planos RF04)
-- Cada papel tem um cadastro de acesso independente (DVP v2.6).

CREATE TYPE status_organizacao AS ENUM ('EM_HABILITACAO', 'HABILITADA', 'SUSPENSA');
CREATE TYPE status_cadastro AS ENUM ('ATIVO', 'INATIVO');
CREATE TYPE status_membro AS ENUM ('ATIVO', 'DESATIVADO', 'CANCELADO');

CREATE TABLE organizacao (
    id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome    VARCHAR(150) NOT NULL,
    cnpj    CHAR(14) NOT NULL UNIQUE,
    status  status_organizacao NOT NULL DEFAULT 'EM_HABILITACAO'
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

CREATE TABLE membro (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacao_id  UUID NOT NULL REFERENCES organizacao (id),
    nome            VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    senha_hash      VARCHAR(255) NOT NULL,
    data_adesao     DATE NOT NULL DEFAULT CURRENT_DATE,
    status          status_membro NOT NULL DEFAULT 'ATIVO'
);

-- RF04: planos de associação. Desativar um plano não afeta os membros já vinculados.
CREATE TABLE plano_associacao (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacao_id    UUID NOT NULL REFERENCES organizacao (id),
    nome              VARCHAR(100) NOT NULL,
    valor_referencia  NUMERIC(10, 2) NOT NULL CHECK (valor_referencia >= 0),
    duracao_dias      INTEGER NOT NULL CHECK (duracao_dias > 0),
    status            status_cadastro NOT NULL DEFAULT 'ATIVO'
);

-- Nome do plano único dentro da organização.
CREATE UNIQUE INDEX plano_associacao_nome_un ON plano_associacao (organizacao_id, lower(nome));

-- E-mail único dentro de cada cadastro, sem diferenciar maiúsculas.
CREATE UNIQUE INDEX administrador_email_un ON administrador (lower(email));
CREATE UNIQUE INDEX operador_email_un ON operador (lower(email));
CREATE UNIQUE INDEX membro_email_un ON membro (lower(email));
