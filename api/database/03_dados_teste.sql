-- MembroPass — Dados de teste (somente desenvolvimento)
-- Senha de todas as contas: Senha@123

INSERT INTO organizacao (id, nome, cnpj, status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Clube Exemplo', '12345678000190', 'HABILITADA');

INSERT INTO administrador (organizacao_id, nome, email, senha_hash) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Ana Administradora', 'admin@membropass.dev',
     '$2b$10$swt93Y0d1fTr4hvjd3wBQOuZTq9fKiOwJjl4/TSXpC.xVg3yFcIW2');

INSERT INTO operador (organizacao_id, nome, email, senha_hash) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Otávio Operador', 'operador@membropass.dev',
     '$2b$10$swt93Y0d1fTr4hvjd3wBQOuZTq9fKiOwJjl4/TSXpC.xVg3yFcIW2');

INSERT INTO plano_associacao (organizacao_id, nome, valor_referencia, duracao_dias) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Mensal', 89.90, 30),
    ('00000000-0000-0000-0000-000000000001', 'Trimestral', 239.90, 90),
    ('00000000-0000-0000-0000-000000000001', 'Anual', 899.00, 365);

INSERT INTO beneficio (id, organizacao_id, nome, descricao, parceiro, tipo_desconto, valor_desconto, vig_inicio, vig_fim) VALUES
    ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-000000000001',
     'Desconto na farmácia', 'Apresente a carteirinha no caixa.', 'Farmácia Central', 'PERCENTUAL', 15, NULL, NULL),
    ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-000000000001',
     'Avaliação física', 'Uma avaliação por ciclo.', NULL, 'VALOR', 50, '2026-01-01', '2026-12-31');

-- Farmácia: todos os planos. Avaliação física: só Trimestral e Anual.
INSERT INTO plano_beneficio (plano_id, beneficio_id)
SELECT p.id, '00000000-0000-0000-0000-0000000000b1'::uuid FROM plano_associacao p
UNION ALL
SELECT p.id, '00000000-0000-0000-0000-0000000000b2'::uuid FROM plano_associacao p WHERE p.nome IN ('Trimestral', 'Anual');

-- A carteirinha de cada membro é emitida pelo trigger membro_emitir_carteirinha.
INSERT INTO membro (organizacao_id, nome, email, senha_hash, telefone, plano_id, data_adesao)
SELECT '00000000-0000-0000-0000-000000000001', m.nome, m.email,
       '$2b$10$swt93Y0d1fTr4hvjd3wBQOuZTq9fKiOwJjl4/TSXpC.xVg3yFcIW2', m.telefone, p.id,
       CURRENT_DATE - m.dias_atras
FROM (VALUES
    ('Marina Membro', 'membro@membropass.dev', '(54) 99999-0001', 'Mensal', 10),
    ('Bruno Souza', 'bruno@exemplo.com', NULL, 'Mensal', 26),
    ('Carla Dias', 'carla@exemplo.com', '(54) 98888-0002', 'Trimestral', 100),
    ('Diego Lima', 'diego@exemplo.com', NULL, 'Anual', 40)
) AS m (nome, email, telefone, plano, dias_atras)
JOIN plano_associacao p ON p.nome = m.plano;

INSERT INTO unidade_evento (id, organizacao_id, nome, tipo, localizacao, data_inicio, data_fim) VALUES
    ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-000000000001',
     'Sede Central', 'UNIDADE', 'Rua das Flores, 100 - Centro', NULL, NULL),
    ('00000000-0000-0000-0000-0000000000e2', '00000000-0000-0000-0000-000000000001',
     'Torneio de Verão', 'EVENTO', 'Ginásio Municipal', CURRENT_DATE + 20, CURRENT_DATE + 22);

-- Sede: todos os planos. Torneio: só Trimestral e Anual.
INSERT INTO unidade_evento_plano (unidade_evento_id, plano_id)
SELECT '00000000-0000-0000-0000-0000000000e1'::uuid, p.id FROM plano_associacao p
UNION ALL
SELECT '00000000-0000-0000-0000-0000000000e2'::uuid, p.id FROM plano_associacao p WHERE p.nome IN ('Trimestral', 'Anual');
