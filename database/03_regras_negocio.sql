-- MembroPass — Regras de negócio: triggers, procedures e views
-- Gerado a partir de api/prisma/migrations/20261006231721_regras_negocio (npm run db:sql).

-- =============================================================================
-- MembroPass — Regras de negócio no banco de dados
-- Restrições, funções, triggers, procedures e views (DVP v2.6)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------------------------
-- 1. Restrições de domínio (CHECK)
-- -----------------------------------------------------------------------------

ALTER TABLE organizacao
  ADD CONSTRAINT ck_organizacao_cnpj CHECK (cnpj ~ '^[0-9]{14}$'),
  ADD CONSTRAINT ck_organizacao_cor CHECK (cor_principal IS NULL OR cor_principal ~ '^#[0-9A-Fa-f]{6}$');

-- RF04: a duração do ciclo define o vencimento; o valor é apenas informativo.
ALTER TABLE plano_associacao
  ADD CONSTRAINT ck_plano_duracao CHECK (duracao_dias > 0),
  ADD CONSTRAINT ck_plano_valor CHECK (valor_referencia >= 0);

-- RF08: desconto percentual ou em valor, com vigência opcional.
ALTER TABLE beneficio
  ADD CONSTRAINT ck_beneficio_valor CHECK (
    valor_desconto > 0 AND (tipo_desconto <> 'PERCENTUAL' OR valor_desconto <= 100)
  ),
  ADD CONSTRAINT ck_beneficio_vigencia CHECK (vig_inicio IS NULL OR vig_fim IS NULL OR vig_fim >= vig_inicio);

-- RF11: eventos têm data de início e término; unidades fixas não.
ALTER TABLE unidade_evento
  ADD CONSTRAINT ck_unidade_evento_datas CHECK (
    (tipo = 'UNIDADE' AND data_inicio IS NULL AND data_fim IS NULL)
    OR (tipo = 'EVENTO' AND data_inicio IS NOT NULL AND data_fim IS NOT NULL AND data_fim >= data_inicio)
  );

ALTER TABLE carteirinha
  ADD CONSTRAINT ck_carteirinha_vencimento CHECK (data_vencimento >= data_emissao),
  ADD CONSTRAINT ck_carteirinha_qr_versao CHECK (qr_versao >= 1);

-- -----------------------------------------------------------------------------
-- 2. Funções auxiliares
-- -----------------------------------------------------------------------------

-- RF05 / RNF06: situação exibida da carteirinha. "Vencida" e "vencendo" são
-- calculadas pela data; o sistema nunca bloqueia automaticamente.
CREATE OR REPLACE FUNCTION fn_situacao_carteirinha(
  p_status status_carteirinha,
  p_vencimento date,
  p_hoje date DEFAULT CURRENT_DATE
) RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT CASE
    WHEN p_status <> 'ATIVA'        THEN p_status::text
    WHEN p_vencimento < p_hoje      THEN 'VENCIDA'
    WHEN p_vencimento <= p_hoje + 7 THEN 'VENCENDO'
    ELSE 'ATIVA'
  END
$$;

-- RNF08: token aleatório e não sequencial usado na assinatura do QR Code.
CREATE OR REPLACE FUNCTION fn_novo_token_qr() RETURNS varchar
LANGUAGE sql VOLATILE AS $$
  SELECT encode(digest(gen_random_bytes(32), 'sha256'), 'hex')
$$;

-- -----------------------------------------------------------------------------
-- 3. Triggers
-- -----------------------------------------------------------------------------

-- RF01: um mesmo e-mail não pode existir em mais de um dos três cadastros.
-- A restrição UNIQUE de cada tabela não cobre as outras duas.
CREATE OR REPLACE FUNCTION fn_email_unico_entre_cadastros() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.email := lower(trim(NEW.email));

  IF (TG_TABLE_NAME <> 'administrador' AND EXISTS (SELECT 1 FROM administrador WHERE email = NEW.email))
     OR (TG_TABLE_NAME <> 'operador' AND EXISTS (SELECT 1 FROM operador WHERE email = NEW.email))
     OR (TG_TABLE_NAME <> 'membro' AND EXISTS (SELECT 1 FROM membro WHERE email = NEW.email)) THEN
    RAISE EXCEPTION 'O e-mail % já está cadastrado em outro perfil.', NEW.email
      USING ERRCODE = 'unique_violation';
  END IF;

  RETURN NEW;
END
$$;

CREATE TRIGGER trg_administrador_email_unico
  BEFORE INSERT OR UPDATE OF email ON administrador
  FOR EACH ROW EXECUTE FUNCTION fn_email_unico_entre_cadastros();

CREATE TRIGGER trg_operador_email_unico
  BEFORE INSERT OR UPDATE OF email ON operador
  FOR EACH ROW EXECUTE FUNCTION fn_email_unico_entre_cadastros();

CREATE TRIGGER trg_membro_email_unico
  BEFORE INSERT OR UPDATE OF email ON membro
  FOR EACH ROW EXECUTE FUNCTION fn_email_unico_entre_cadastros();

-- RNF01 / HU07: o plano do membro deve ser da mesma organização e estar ativo
-- no momento do vínculo.
CREATE OR REPLACE FUNCTION fn_validar_plano_membro() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  v_organizacao_id uuid;
  v_status status_cadastro;
BEGIN
  SELECT organizacao_id, status INTO v_organizacao_id, v_status
    FROM plano_associacao WHERE id = NEW.plano_id;

  IF v_organizacao_id <> NEW.organizacao_id THEN
    RAISE EXCEPTION 'O plano informado não pertence à organização do membro.';
  END IF;

  IF (TG_OP = 'INSERT' OR NEW.plano_id IS DISTINCT FROM OLD.plano_id) AND v_status <> 'ATIVO' THEN
    RAISE EXCEPTION 'O plano informado está inativo.';
  END IF;

  RETURN NEW;
END
$$;

CREATE TRIGGER trg_membro_validar_plano
  BEFORE INSERT OR UPDATE OF plano_id, organizacao_id ON membro
  FOR EACH ROW EXECUTE FUNCTION fn_validar_plano_membro();

-- RF05: a carteirinha é emitida automaticamente quando o membro é vinculado a
-- um plano, com vencimento calculado pela duração do plano.
CREATE OR REPLACE FUNCTION fn_emitir_carteirinha() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  v_duracao integer;
BEGIN
  SELECT duracao_dias INTO v_duracao FROM plano_associacao WHERE id = NEW.plano_id;

  INSERT INTO carteirinha (id, membro_id, qr_token_hash, qr_versao, data_emissao, data_vencimento, status)
  VALUES (gen_random_uuid(), NEW.id, fn_novo_token_qr(), 1, NEW.data_adesao, NEW.data_adesao + v_duracao, 'ATIVA');

  RETURN NEW;
END
$$;

CREATE TRIGGER trg_membro_emitir_carteirinha
  AFTER INSERT ON membro
  FOR EACH ROW EXECUTE FUNCTION fn_emitir_carteirinha();

-- RF06: ao desativar ou cancelar o membro, a carteirinha é invalidada imediatamente.
CREATE OR REPLACE FUNCTION fn_invalidar_carteirinha() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status <> 'ATIVO' AND OLD.status = 'ATIVO' THEN
    UPDATE carteirinha
       SET status = 'INVALIDADA', qr_versao = qr_versao + 1, qr_token_hash = fn_novo_token_qr()
     WHERE membro_id = NEW.id;
  END IF;

  RETURN NEW;
END
$$;

CREATE TRIGGER trg_membro_invalidar_carteirinha
  AFTER UPDATE OF status ON membro
  FOR EACH ROW EXECUTE FUNCTION fn_invalidar_carteirinha();

-- RNF01: planos e benefícios vinculados devem ser da mesma organização.
CREATE OR REPLACE FUNCTION fn_validar_plano_beneficio() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT organizacao_id FROM plano_associacao WHERE id = NEW.plano_id)
     <> (SELECT organizacao_id FROM beneficio WHERE id = NEW.beneficio_id) THEN
    RAISE EXCEPTION 'Plano e benefício pertencem a organizações diferentes.';
  END IF;

  RETURN NEW;
END
$$;

CREATE TRIGGER trg_plano_beneficio_mesma_organizacao
  BEFORE INSERT OR UPDATE ON plano_beneficio
  FOR EACH ROW EXECUTE FUNCTION fn_validar_plano_beneficio();

-- RNF01: unidades/eventos e planos aceitos devem ser da mesma organização.
CREATE OR REPLACE FUNCTION fn_validar_unidade_evento_plano() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT organizacao_id FROM plano_associacao WHERE id = NEW.plano_id)
     <> (SELECT organizacao_id FROM unidade_evento WHERE id = NEW.unidade_evento_id) THEN
    RAISE EXCEPTION 'Unidade/evento e plano pertencem a organizações diferentes.';
  END IF;

  RETURN NEW;
END
$$;

CREATE TRIGGER trg_unidade_evento_plano_mesma_organizacao
  BEFORE INSERT OR UPDATE ON unidade_evento_plano
  FOR EACH ROW EXECUTE FUNCTION fn_validar_unidade_evento_plano();

-- RNF01 / RF10: o operador só registra check-in em unidades da sua organização.
CREATE OR REPLACE FUNCTION fn_validar_check_in() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT organizacao_id FROM operador WHERE id = NEW.operador_id)
     <> (SELECT organizacao_id FROM unidade_evento WHERE id = NEW.unidade_evento_id) THEN
    RAISE EXCEPTION 'O operador não pertence à organização da unidade/evento.';
  END IF;

  RETURN NEW;
END
$$;

CREATE TRIGGER trg_check_in_mesma_organizacao
  BEFORE INSERT ON check_in
  FOR EACH ROW EXECUTE FUNCTION fn_validar_check_in();

-- RNF11: o histórico de auditoria é imutável.
CREATE OR REPLACE FUNCTION fn_auditoria_imutavel() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'Registros de auditoria não podem ser alterados nem excluídos.';
END
$$;

CREATE TRIGGER trg_auditoria_imutavel
  BEFORE UPDATE OR DELETE ON auditoria
  FOR EACH ROW EXECUTE FUNCTION fn_auditoria_imutavel();

CREATE TRIGGER trg_auditoria_imutavel_truncate
  BEFORE TRUNCATE ON auditoria
  FOR EACH STATEMENT EXECUTE FUNCTION fn_auditoria_imutavel();

-- -----------------------------------------------------------------------------
-- 4. Procedures
-- -----------------------------------------------------------------------------

-- Garante que o administrador está ativo e é da mesma organização do membro.
-- Retorna a organização do membro.
CREATE OR REPLACE FUNCTION fn_validar_administrador_membro(
  p_administrador_id uuid,
  p_membro_id uuid
) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE
  v_organizacao_membro uuid;
  v_organizacao_admin uuid;
  v_status_admin status_cadastro;
BEGIN
  SELECT organizacao_id INTO v_organizacao_membro FROM membro WHERE id = p_membro_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Membro não encontrado.';
  END IF;

  SELECT organizacao_id, status INTO v_organizacao_admin, v_status_admin
    FROM administrador WHERE id = p_administrador_id;
  IF NOT FOUND OR v_status_admin <> 'ATIVO' THEN
    RAISE EXCEPTION 'Administrador não encontrado ou inativo.';
  END IF;

  IF v_organizacao_admin <> v_organizacao_membro THEN
    RAISE EXCEPTION 'O administrador não pertence à organização do membro.';
  END IF;

  RETURN v_organizacao_membro;
END
$$;

-- RF07 / HU10: confirma o pagamento recebido fora do app e libera um novo ciclo.
-- Novo vencimento = data da confirmação + duração do plano. A carteirinha é
-- reativada (se estava bloqueada) e o QR Code muda de versão.
CREATE OR REPLACE PROCEDURE sp_liberar_ciclo(
  p_membro_id uuid,
  p_administrador_id uuid,
  p_data_referencia date,
  INOUT p_novo_vencimento date DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
  v_organizacao_id uuid;
  v_status_membro status_membro;
  v_duracao integer;
BEGIN
  v_organizacao_id := fn_validar_administrador_membro(p_administrador_id, p_membro_id);

  SELECT m.status, p.duracao_dias INTO v_status_membro, v_duracao
    FROM membro m JOIN plano_associacao p ON p.id = m.plano_id
   WHERE m.id = p_membro_id
     FOR UPDATE OF m;

  IF v_status_membro <> 'ATIVO' THEN
    RAISE EXCEPTION 'Não é possível liberar ciclo para um membro desativado ou cancelado.';
  END IF;

  p_novo_vencimento := CURRENT_DATE + v_duracao;

  INSERT INTO liberacao_ciclo (id, membro_id, confirmado_por, data_referencia, data_confirmacao, novo_vencimento)
  VALUES (gen_random_uuid(), p_membro_id, p_administrador_id, p_data_referencia, now(), p_novo_vencimento);

  UPDATE carteirinha
     SET data_vencimento = p_novo_vencimento,
         status = 'ATIVA',
         qr_versao = qr_versao + 1,
         qr_token_hash = fn_novo_token_qr()
   WHERE membro_id = p_membro_id;

  INSERT INTO auditoria (id, organizacao_id, administrador_id, acao, entidade, entidade_id, justificativa, data_hora)
  VALUES (gen_random_uuid(), v_organizacao_id, p_administrador_id, 'LIBERACAO_CICLO', 'membro', p_membro_id,
          'Pagamento confirmado com data de referência ' || to_char(p_data_referencia, 'DD/MM/YYYY'), now());
END
$$;

-- RF07 / HU11: bloqueio manual da carteirinha, sempre por decisão do administrador.
CREATE OR REPLACE PROCEDURE sp_bloquear_carteirinha(
  p_membro_id uuid,
  p_administrador_id uuid,
  p_justificativa text
)
LANGUAGE plpgsql AS $$
DECLARE
  v_organizacao_id uuid;
  v_status status_carteirinha;
BEGIN
  v_organizacao_id := fn_validar_administrador_membro(p_administrador_id, p_membro_id);

  SELECT status INTO v_status FROM carteirinha WHERE membro_id = p_membro_id FOR UPDATE;

  IF v_status <> 'ATIVA' THEN
    RAISE EXCEPTION 'Somente carteirinhas ativas podem ser bloqueadas.';
  END IF;

  UPDATE carteirinha
     SET status = 'BLOQUEADA',
         qr_versao = qr_versao + 1,
         qr_token_hash = fn_novo_token_qr()
   WHERE membro_id = p_membro_id;

  INSERT INTO auditoria (id, organizacao_id, administrador_id, acao, entidade, entidade_id, justificativa, data_hora)
  VALUES (gen_random_uuid(), v_organizacao_id, p_administrador_id, 'BLOQUEIO_MANUAL', 'membro', p_membro_id,
          p_justificativa, now());
END
$$;

-- -----------------------------------------------------------------------------
-- 5. Views
-- -----------------------------------------------------------------------------

-- HU12 / RF15: situação de cada membro para acompanhamento de vencimentos.
CREATE OR REPLACE VIEW vw_situacao_membros AS
SELECT
  m.organizacao_id,
  m.id              AS membro_id,
  m.nome            AS membro,
  m.email,
  p.nome            AS plano,
  c.data_vencimento,
  c.data_vencimento - CURRENT_DATE AS dias_para_vencer,
  CASE WHEN m.status = 'ATIVO'
       THEN fn_situacao_carteirinha(c.status, c.data_vencimento)
       ELSE m.status::text
  END               AS situacao
FROM membro m
JOIN plano_associacao p ON p.id = m.plano_id
JOIN carteirinha c      ON c.membro_id = m.id;
