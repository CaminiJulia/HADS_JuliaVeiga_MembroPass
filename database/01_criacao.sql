-- MembroPass — Criação das tabelas
-- Gerado a partir de api/prisma/migrations/20261006231633_criacao_tabelas (npm run db:sql).

-- CreateEnum
CREATE TYPE "status_organizacao" AS ENUM ('EM_HABILITACAO', 'HABILITADA', 'SUSPENSA');

-- CreateEnum
CREATE TYPE "status_cadastro" AS ENUM ('ATIVO', 'INATIVO');

-- CreateEnum
CREATE TYPE "status_membro" AS ENUM ('ATIVO', 'DESATIVADO', 'CANCELADO');

-- CreateEnum
CREATE TYPE "status_carteirinha" AS ENUM ('ATIVA', 'BLOQUEADA', 'INVALIDADA');

-- CreateEnum
CREATE TYPE "tipo_desconto" AS ENUM ('PERCENTUAL', 'VALOR');

-- CreateEnum
CREATE TYPE "tipo_unidade_evento" AS ENUM ('UNIDADE', 'EVENTO');

-- CreateEnum
CREATE TYPE "resultado_check_in" AS ENUM ('APROVADO', 'REJEITADO_QR_INVALIDO', 'REJEITADO_CARTEIRINHA_BLOQUEADA', 'REJEITADO_CARTEIRINHA_VENCIDA', 'REJEITADO_PLANO_NAO_ACEITO', 'REJEITADO_FORA_DO_PERIODO');

-- CreateEnum
CREATE TYPE "acao_auditoria" AS ENUM ('LIBERACAO_CICLO', 'BLOQUEIO_MANUAL', 'DESATIVACAO_MEMBRO', 'CANCELAMENTO_MEMBRO', 'EDICAO_PLANO', 'ALTERACAO_IDENTIDADE_VISUAL');

-- CreateTable
CREATE TABLE "organizacao" (
    "id" UUID NOT NULL,
    "nome" VARCHAR(150) NOT NULL,
    "cnpj" CHAR(14) NOT NULL,
    "logo_url" VARCHAR(500),
    "cor_principal" CHAR(7),
    "status" "status_organizacao" NOT NULL DEFAULT 'EM_HABILITACAO',

    CONSTRAINT "organizacao_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "administrador" (
    "id" UUID NOT NULL,
    "organizacao_id" UUID NOT NULL,
    "nome" VARCHAR(150) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "senha_hash" VARCHAR(255) NOT NULL,
    "telefone" VARCHAR(20),
    "status" "status_cadastro" NOT NULL DEFAULT 'ATIVO',

    CONSTRAINT "administrador_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "operador" (
    "id" UUID NOT NULL,
    "organizacao_id" UUID NOT NULL,
    "nome" VARCHAR(150) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "senha_hash" VARCHAR(255) NOT NULL,
    "status" "status_cadastro" NOT NULL DEFAULT 'ATIVO',

    CONSTRAINT "operador_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "membro" (
    "id" UUID NOT NULL,
    "organizacao_id" UUID NOT NULL,
    "nome" VARCHAR(150) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "senha_hash" VARCHAR(255) NOT NULL,
    "telefone" VARCHAR(20),
    "plano_id" UUID NOT NULL,
    "data_adesao" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" "status_membro" NOT NULL DEFAULT 'ATIVO',

    CONSTRAINT "membro_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plano_associacao" (
    "id" UUID NOT NULL,
    "organizacao_id" UUID NOT NULL,
    "nome" VARCHAR(100) NOT NULL,
    "valor_referencia" DECIMAL(10,2) NOT NULL,
    "duracao_dias" INTEGER NOT NULL,
    "status" "status_cadastro" NOT NULL DEFAULT 'ATIVO',

    CONSTRAINT "plano_associacao_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "beneficio" (
    "id" UUID NOT NULL,
    "organizacao_id" UUID NOT NULL,
    "nome" VARCHAR(100) NOT NULL,
    "descricao" TEXT,
    "parceiro" VARCHAR(150),
    "tipo_desconto" "tipo_desconto" NOT NULL,
    "valor_desconto" DECIMAL(10,2) NOT NULL,
    "vig_inicio" DATE,
    "vig_fim" DATE,

    CONSTRAINT "beneficio_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plano_beneficio" (
    "plano_id" UUID NOT NULL,
    "beneficio_id" UUID NOT NULL,

    CONSTRAINT "plano_beneficio_pkey" PRIMARY KEY ("plano_id","beneficio_id")
);

-- CreateTable
CREATE TABLE "carteirinha" (
    "id" UUID NOT NULL,
    "membro_id" UUID NOT NULL,
    "qr_token_hash" VARCHAR(255) NOT NULL,
    "qr_versao" INTEGER NOT NULL DEFAULT 1,
    "data_emissao" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "data_vencimento" DATE NOT NULL,
    "status" "status_carteirinha" NOT NULL DEFAULT 'ATIVA',

    CONSTRAINT "carteirinha_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "liberacao_ciclo" (
    "id" UUID NOT NULL,
    "membro_id" UUID NOT NULL,
    "confirmado_por" UUID NOT NULL,
    "data_referencia" DATE NOT NULL,
    "data_confirmacao" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "novo_vencimento" DATE NOT NULL,

    CONSTRAINT "liberacao_ciclo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "unidade_evento" (
    "id" UUID NOT NULL,
    "organizacao_id" UUID NOT NULL,
    "nome" VARCHAR(150) NOT NULL,
    "tipo" "tipo_unidade_evento" NOT NULL,
    "localizacao" VARCHAR(255),
    "data_inicio" TIMESTAMPTZ,
    "data_fim" TIMESTAMPTZ,

    CONSTRAINT "unidade_evento_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "unidade_evento_plano" (
    "unidade_evento_id" UUID NOT NULL,
    "plano_id" UUID NOT NULL,

    CONSTRAINT "unidade_evento_plano_pkey" PRIMARY KEY ("unidade_evento_id","plano_id")
);

-- CreateTable
CREATE TABLE "check_in" (
    "id" UUID NOT NULL,
    "carteirinha_id" UUID,
    "unidade_evento_id" UUID NOT NULL,
    "operador_id" UUID NOT NULL,
    "data_hora" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resultado" "resultado_check_in" NOT NULL,

    CONSTRAINT "check_in_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "auditoria" (
    "id" UUID NOT NULL,
    "organizacao_id" UUID NOT NULL,
    "administrador_id" UUID NOT NULL,
    "acao" "acao_auditoria" NOT NULL,
    "entidade" VARCHAR(50) NOT NULL,
    "entidade_id" UUID NOT NULL,
    "justificativa" TEXT,
    "data_hora" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "auditoria_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "organizacao_cnpj_key" ON "organizacao"("cnpj");

-- CreateIndex
CREATE UNIQUE INDEX "administrador_email_key" ON "administrador"("email");

-- CreateIndex
CREATE INDEX "administrador_organizacao_id_idx" ON "administrador"("organizacao_id");

-- CreateIndex
CREATE UNIQUE INDEX "operador_email_key" ON "operador"("email");

-- CreateIndex
CREATE INDEX "operador_organizacao_id_idx" ON "operador"("organizacao_id");

-- CreateIndex
CREATE UNIQUE INDEX "membro_email_key" ON "membro"("email");

-- CreateIndex
CREATE INDEX "membro_organizacao_id_idx" ON "membro"("organizacao_id");

-- CreateIndex
CREATE INDEX "membro_plano_id_idx" ON "membro"("plano_id");

-- CreateIndex
CREATE INDEX "plano_associacao_organizacao_id_idx" ON "plano_associacao"("organizacao_id");

-- CreateIndex
CREATE INDEX "beneficio_organizacao_id_idx" ON "beneficio"("organizacao_id");

-- CreateIndex
CREATE UNIQUE INDEX "carteirinha_membro_id_key" ON "carteirinha"("membro_id");

-- CreateIndex
CREATE INDEX "liberacao_ciclo_membro_id_idx" ON "liberacao_ciclo"("membro_id");

-- CreateIndex
CREATE INDEX "unidade_evento_organizacao_id_idx" ON "unidade_evento"("organizacao_id");

-- CreateIndex
CREATE INDEX "check_in_carteirinha_id_idx" ON "check_in"("carteirinha_id");

-- CreateIndex
CREATE INDEX "check_in_unidade_evento_id_data_hora_idx" ON "check_in"("unidade_evento_id", "data_hora");

-- CreateIndex
CREATE INDEX "auditoria_organizacao_id_data_hora_idx" ON "auditoria"("organizacao_id", "data_hora");

-- AddForeignKey
ALTER TABLE "administrador" ADD CONSTRAINT "administrador_organizacao_id_fkey" FOREIGN KEY ("organizacao_id") REFERENCES "organizacao"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "operador" ADD CONSTRAINT "operador_organizacao_id_fkey" FOREIGN KEY ("organizacao_id") REFERENCES "organizacao"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "membro" ADD CONSTRAINT "membro_organizacao_id_fkey" FOREIGN KEY ("organizacao_id") REFERENCES "organizacao"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "membro" ADD CONSTRAINT "membro_plano_id_fkey" FOREIGN KEY ("plano_id") REFERENCES "plano_associacao"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plano_associacao" ADD CONSTRAINT "plano_associacao_organizacao_id_fkey" FOREIGN KEY ("organizacao_id") REFERENCES "organizacao"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "beneficio" ADD CONSTRAINT "beneficio_organizacao_id_fkey" FOREIGN KEY ("organizacao_id") REFERENCES "organizacao"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plano_beneficio" ADD CONSTRAINT "plano_beneficio_plano_id_fkey" FOREIGN KEY ("plano_id") REFERENCES "plano_associacao"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plano_beneficio" ADD CONSTRAINT "plano_beneficio_beneficio_id_fkey" FOREIGN KEY ("beneficio_id") REFERENCES "beneficio"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "carteirinha" ADD CONSTRAINT "carteirinha_membro_id_fkey" FOREIGN KEY ("membro_id") REFERENCES "membro"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "liberacao_ciclo" ADD CONSTRAINT "liberacao_ciclo_membro_id_fkey" FOREIGN KEY ("membro_id") REFERENCES "membro"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "liberacao_ciclo" ADD CONSTRAINT "liberacao_ciclo_confirmado_por_fkey" FOREIGN KEY ("confirmado_por") REFERENCES "administrador"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "unidade_evento" ADD CONSTRAINT "unidade_evento_organizacao_id_fkey" FOREIGN KEY ("organizacao_id") REFERENCES "organizacao"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "unidade_evento_plano" ADD CONSTRAINT "unidade_evento_plano_unidade_evento_id_fkey" FOREIGN KEY ("unidade_evento_id") REFERENCES "unidade_evento"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "unidade_evento_plano" ADD CONSTRAINT "unidade_evento_plano_plano_id_fkey" FOREIGN KEY ("plano_id") REFERENCES "plano_associacao"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_in" ADD CONSTRAINT "check_in_carteirinha_id_fkey" FOREIGN KEY ("carteirinha_id") REFERENCES "carteirinha"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_in" ADD CONSTRAINT "check_in_unidade_evento_id_fkey" FOREIGN KEY ("unidade_evento_id") REFERENCES "unidade_evento"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_in" ADD CONSTRAINT "check_in_operador_id_fkey" FOREIGN KEY ("operador_id") REFERENCES "operador"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "auditoria" ADD CONSTRAINT "auditoria_organizacao_id_fkey" FOREIGN KEY ("organizacao_id") REFERENCES "organizacao"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "auditoria" ADD CONSTRAINT "auditoria_administrador_id_fkey" FOREIGN KEY ("administrador_id") REFERENCES "administrador"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
