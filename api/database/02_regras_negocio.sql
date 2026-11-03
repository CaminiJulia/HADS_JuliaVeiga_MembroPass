-- MembroPass — Regras de negócio no banco (triggers e funções)

-- RF01: o e-mail é único entre os três cadastros (administrador, operador e
-- membro), porque o login descobre o papel pelo cadastro em que o e-mail está.
CREATE FUNCTION verificar_email_unico() RETURNS trigger AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM (
            SELECT 'administrador' AS tabela, id, email FROM administrador
            UNION ALL SELECT 'operador', id, email FROM operador
            UNION ALL SELECT 'membro', id, email FROM membro
        ) contas
        WHERE lower(contas.email) = lower(NEW.email)
          AND NOT (contas.tabela = TG_TABLE_NAME AND contas.id = NEW.id)
    ) THEN
        RAISE EXCEPTION 'O e-mail % já está em uso.', NEW.email
            USING ERRCODE = 'unique_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER administrador_email_unico BEFORE INSERT OR UPDATE OF email ON administrador
    FOR EACH ROW EXECUTE FUNCTION verificar_email_unico();
CREATE TRIGGER operador_email_unico BEFORE INSERT OR UPDATE OF email ON operador
    FOR EACH ROW EXECUTE FUNCTION verificar_email_unico();
CREATE TRIGGER membro_email_unico BEFORE INSERT OR UPDATE OF email ON membro
    FOR EACH ROW EXECUTE FUNCTION verificar_email_unico();

-- RF05: ao cadastrar o membro, a carteirinha é emitida automaticamente,
-- vencendo após a duração do plano escolhido.
CREATE FUNCTION emitir_carteirinha() RETURNS trigger AS $$
BEGIN
    INSERT INTO carteirinha (membro_id, data_emissao, data_vencimento)
    SELECT NEW.id, NEW.data_adesao, NEW.data_adesao + p.duracao_dias
    FROM plano_associacao p
    WHERE p.id = NEW.plano_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER membro_emitir_carteirinha AFTER INSERT ON membro
    FOR EACH ROW EXECUTE FUNCTION emitir_carteirinha();

-- O plano do membro precisa ser da mesma organização dele.
CREATE FUNCTION verificar_plano_do_membro() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM plano_associacao
        WHERE id = NEW.plano_id AND organizacao_id = NEW.organizacao_id
    ) THEN
        RAISE EXCEPTION 'O plano não pertence à organização do membro.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER membro_plano_da_organizacao BEFORE INSERT OR UPDATE OF plano_id ON membro
    FOR EACH ROW EXECUTE FUNCTION verificar_plano_do_membro();

-- RF16: a auditoria é imutável. Nenhuma linha pode ser alterada ou apagada.
CREATE FUNCTION impedir_alteracao_auditoria() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'O registro de auditoria não pode ser alterado nem excluído.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auditoria_imutavel BEFORE UPDATE OR DELETE ON auditoria
    FOR EACH ROW EXECUTE FUNCTION impedir_alteracao_auditoria();

-- RF07: libera um novo ciclo após o administrador confirmar o pagamento.
-- O novo vencimento conta a partir do vencimento atual ou da data do
-- pagamento (o que for maior), somando a duração do plano atual do membro.
-- A carteirinha volta a ficar ativa e ganha nova versão de QR Code.
-- Registra a liberação e a auditoria. Devolve o novo vencimento.
CREATE FUNCTION liberar_ciclo(
    p_membro_id UUID,
    p_administrador_id UUID,
    p_data_pagamento DATE
) RETURNS DATE AS $$
DECLARE
    v_organizacao_id  UUID;
    v_vencimento      DATE;
    v_duracao         INTEGER;
    v_valor           NUMERIC(10, 2);
    v_plano           VARCHAR(100);
    v_novo            DATE;
BEGIN
    SELECT m.organizacao_id, c.data_vencimento, p.duracao_dias, p.valor_referencia, p.nome
    INTO v_organizacao_id, v_vencimento, v_duracao, v_valor, v_plano
    FROM membro m
    JOIN carteirinha c ON c.membro_id = m.id
    JOIN plano_associacao p ON p.id = m.plano_id
    WHERE m.id = p_membro_id AND m.status = 'ATIVO'
    FOR UPDATE OF c;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Membro não encontrado ou desativado.';
    END IF;
    IF p_data_pagamento > CURRENT_DATE THEN
        RAISE EXCEPTION 'A data do pagamento não pode ser futura.';
    END IF;

    v_novo := GREATEST(v_vencimento, p_data_pagamento) + v_duracao;

    UPDATE carteirinha
    SET data_vencimento = v_novo, status = 'ATIVA', qr_versao = qr_versao + 1
    WHERE membro_id = p_membro_id;

    INSERT INTO liberacao_ciclo (membro_id, confirmado_por, data_pagamento,
                                 vencimento_anterior, novo_vencimento, valor_referencia)
    VALUES (p_membro_id, p_administrador_id, p_data_pagamento, v_vencimento, v_novo, v_valor);

    INSERT INTO auditoria (organizacao_id, administrador_id, acao, entidade, entidade_id, descricao)
    VALUES (v_organizacao_id, p_administrador_id, 'LIBERACAO_CICLO', 'membro', p_membro_id,
            format('Pagamento de R$ %s em %s confirmado (plano %s). Vencimento: %s → %s.',
                   replace(to_char(v_valor, 'FM99999990.00'), '.', ','),
                   to_char(p_data_pagamento, 'DD/MM/YYYY'),
                   v_plano, to_char(v_vencimento, 'DD/MM/YYYY'), to_char(v_novo, 'DD/MM/YYYY')));

    RETURN v_novo;
END;
$$ LANGUAGE plpgsql;
