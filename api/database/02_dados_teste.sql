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

INSERT INTO membro (organizacao_id, nome, email, senha_hash) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Marina Membro', 'membro@membropass.dev',
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
