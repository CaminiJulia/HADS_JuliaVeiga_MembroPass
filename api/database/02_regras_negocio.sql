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
