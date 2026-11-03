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
