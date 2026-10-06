-- =============================================================================
-- MembroPass — Dados para testes
-- Executar em um banco recém-criado (npm run db:reset, na pasta api).
-- Senha de todos os usuários de teste: Senha@123
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Organizações
-- -----------------------------------------------------------------------------
INSERT INTO organizacao (id, nome, cnpj, logo_url, cor_principal, status) VALUES
  ('a0000000-0000-4000-8000-000000000001', 'Clube Atlético Passo Fundo', '12345678000190', NULL, '#1E3A8A', 'HABILITADA'),
  ('a0000000-0000-4000-8000-000000000002', 'Academia Movimento',         '98765432000110', NULL, '#B91C1C', 'HABILITADA'),
  ('a0000000-0000-4000-8000-000000000003', 'Associação Comercial Norte', '11222333000144', NULL, NULL,      'EM_HABILITACAO');

-- -----------------------------------------------------------------------------
-- Administradores e operadores
-- -----------------------------------------------------------------------------
INSERT INTO administrador (id, organizacao_id, nome, email, senha_hash, telefone) VALUES
  ('b0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Marina Oliveira', 'admin@clubeatletico.com.br',     crypt('Senha@123', gen_salt('bf', 10)), '54999990001'),
  ('b0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002', 'Rafael Teixeira', 'admin@academiamovimento.com.br', crypt('Senha@123', gen_salt('bf', 10)), '54999990002'),
  ('b0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000003', 'Sônia Ribeiro',   'admin@acnorte.com.br',           crypt('Senha@123', gen_salt('bf', 10)), '54999990003');

INSERT INTO operador (id, organizacao_id, nome, email, senha_hash) VALUES
  ('c0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Portaria Sede',  'portaria@clubeatletico.com.br',     crypt('Senha@123', gen_salt('bf', 10))),
  ('c0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'Equipe Eventos', 'eventos@clubeatletico.com.br',      crypt('Senha@123', gen_salt('bf', 10))),
  ('c0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000002', 'Recepção',       'recepcao@academiamovimento.com.br', crypt('Senha@123', gen_salt('bf', 10)));

-- -----------------------------------------------------------------------------
-- Planos de associação
-- -----------------------------------------------------------------------------
INSERT INTO plano_associacao (id, organizacao_id, nome, valor_referencia, duracao_dias) VALUES
  ('d0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Mensal',          89.90,  30),
  ('d0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'Trimestral',     249.90,  90),
  ('d0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', 'Anual',          899.00, 365),
  ('d0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000001', 'Sócio Fundador',   0.00, 365),
  ('d0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000002', 'Mensal Academia', 119.00,  30);

-- -----------------------------------------------------------------------------
-- Benefícios e vínculo com planos (N:M)
-- -----------------------------------------------------------------------------
INSERT INTO beneficio (id, organizacao_id, nome, descricao, parceiro, tipo_desconto, valor_desconto, vig_inicio, vig_fim) VALUES
  ('e0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Desconto em medicamentos', 'Desconto na compra de medicamentos', 'Farmácia Saúde',   'PERCENTUAL', 10.00, NULL, NULL),
  ('e0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'Almoço com desconto',      'Desconto no almoço executivo',      'Restaurante Sabor', 'VALOR',      20.00, NULL, NULL),
  ('e0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', 'Promoção de inverno',      'Desconto em artigos esportivos',    'Loja Esportiva',   'PERCENTUAL', 15.00, CURRENT_DATE - 90, CURRENT_DATE - 30),
  ('e0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000001', 'Estacionamento gratuito',  'Estacionamento da sede sem custo',  NULL,               'PERCENTUAL', 100.00, NULL, NULL),
  ('e0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000002', 'Avaliação física',         'Avaliação física trimestral',       NULL,               'PERCENTUAL', 50.00, NULL, NULL);

INSERT INTO plano_beneficio (plano_id, beneficio_id) VALUES
  ('d0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001'),
  ('d0000000-0000-4000-8000-000000000002', 'e0000000-0000-4000-8000-000000000001'),
  ('d0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000001'),
  ('d0000000-0000-4000-8000-000000000002', 'e0000000-0000-4000-8000-000000000002'),
  ('d0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000002'),
  ('d0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000003'),
  ('d0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000004'),
  ('d0000000-0000-4000-8000-000000000004', 'e0000000-0000-4000-8000-000000000004'),
  ('d0000000-0000-4000-8000-000000000005', 'e0000000-0000-4000-8000-000000000005');

-- -----------------------------------------------------------------------------
-- Unidades, eventos e planos aceitos (N:M)
-- -----------------------------------------------------------------------------
INSERT INTO unidade_evento (id, organizacao_id, nome, tipo, localizacao, data_inicio, data_fim) VALUES
  ('f0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Sede Social',          'UNIDADE', 'Rua Independência, 1000 — Centro', NULL, NULL),
  ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'Ginásio Poliesportivo', 'UNIDADE', 'Av. Brasil, 2500 — Boqueirão',     NULL, NULL),
  ('f0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', 'Torneio de Primavera',  'EVENTO',  'Ginásio Poliesportivo',
     date_trunc('day', now()) + interval '10 days 8 hours', date_trunc('day', now()) + interval '12 days 18 hours'),
  ('f0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000002', 'Academia Centro',       'UNIDADE', 'Rua Moron, 500 — Centro',           NULL, NULL);

INSERT INTO unidade_evento_plano (unidade_evento_id, plano_id) VALUES
  ('f0000000-0000-4000-8000-000000000001', 'd0000000-0000-4000-8000-000000000001'),
  ('f0000000-0000-4000-8000-000000000001', 'd0000000-0000-4000-8000-000000000002'),
  ('f0000000-0000-4000-8000-000000000001', 'd0000000-0000-4000-8000-000000000003'),
  ('f0000000-0000-4000-8000-000000000001', 'd0000000-0000-4000-8000-000000000004'),
  ('f0000000-0000-4000-8000-000000000002', 'd0000000-0000-4000-8000-000000000002'),
  ('f0000000-0000-4000-8000-000000000002', 'd0000000-0000-4000-8000-000000000003'),
  ('f0000000-0000-4000-8000-000000000003', 'd0000000-0000-4000-8000-000000000003'),
  ('f0000000-0000-4000-8000-000000000004', 'd0000000-0000-4000-8000-000000000005');

-- -----------------------------------------------------------------------------
-- Membros (a carteirinha de cada um é emitida pelo trigger trg_membro_emitir_carteirinha)
-- A data de adesão no passado gera os diferentes status de vencimento.
-- -----------------------------------------------------------------------------
INSERT INTO membro (id, organizacao_id, nome, email, senha_hash, telefone, plano_id, data_adesao) VALUES
  -- Ativa: vence em 25 dias
  ('10000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Ana Souza',      'ana.souza@email.com',      crypt('Senha@123', gen_salt('bf', 10)), '54988880001', 'd0000000-0000-4000-8000-000000000001', CURRENT_DATE - 5),
  -- Vencendo: vence em 4 dias
  ('10000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'Bruno Lima',     'bruno.lima@email.com',     crypt('Senha@123', gen_salt('bf', 10)), '54988880002', 'd0000000-0000-4000-8000-000000000001', CURRENT_DATE - 26),
  -- Vencida há 15 dias, ainda não bloqueada (o sistema não bloqueia sozinho)
  ('10000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', 'Carla Mendes',   'carla.mendes@email.com',   crypt('Senha@123', gen_salt('bf', 10)), '54988880003', 'd0000000-0000-4000-8000-000000000001', CURRENT_DATE - 45),
  -- Vencida e depois bloqueada manualmente (abaixo)
  ('10000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000001', 'Diego Rocha',    'diego.rocha@email.com',    crypt('Senha@123', gen_salt('bf', 10)), '54988880004', 'd0000000-0000-4000-8000-000000000002', CURRENT_DATE - 100),
  -- Ativa no plano anual
  ('10000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000001', 'Elisa Martins',  'elisa.martins@email.com',  crypt('Senha@123', gen_salt('bf', 10)), '54988880005', 'd0000000-0000-4000-8000-000000000003', CURRENT_DATE - 200),
  -- Vencida e depois com ciclo liberado (abaixo)
  ('10000000-0000-4000-8000-000000000006', 'a0000000-0000-4000-8000-000000000001', 'Felipe Costa',   'felipe.costa@email.com',   crypt('Senha@123', gen_salt('bf', 10)), '54988880006', 'd0000000-0000-4000-8000-000000000001', CURRENT_DATE - 35),
  -- Desativado pela organização (abaixo)
  ('10000000-0000-4000-8000-000000000007', 'a0000000-0000-4000-8000-000000000001', 'Gabriela Nunes', 'gabriela.nunes@email.com', crypt('Senha@123', gen_salt('bf', 10)), '54988880007', 'd0000000-0000-4000-8000-000000000002', CURRENT_DATE - 20),
  -- Vinculado a um plano que depois foi desativado (abaixo)
  ('10000000-0000-4000-8000-000000000008', 'a0000000-0000-4000-8000-000000000001', 'Igor Pereira',   'igor.pereira@email.com',   crypt('Senha@123', gen_salt('bf', 10)), '54988880008', 'd0000000-0000-4000-8000-000000000004', CURRENT_DATE - 60),
  -- Membro da outra organização (teste de isolamento multi-tenant)
  ('10000000-0000-4000-8000-000000000009', 'a0000000-0000-4000-8000-000000000002', 'Henrique Alves', 'henrique.alves@email.com', crypt('Senha@123', gen_salt('bf', 10)), '54988880009', 'd0000000-0000-4000-8000-000000000005', CURRENT_DATE - 10);

-- -----------------------------------------------------------------------------
-- Ações administrativas (geram liberação de ciclo e auditoria pelas procedures)
-- -----------------------------------------------------------------------------
CALL sp_bloquear_carteirinha(
  '10000000-0000-4000-8000-000000000004', 'b0000000-0000-4000-8000-000000000001',
  'Mensalidade em atraso há mais de 10 dias, sem retorno do associado.');

CALL sp_liberar_ciclo(
  '10000000-0000-4000-8000-000000000006', 'b0000000-0000-4000-8000-000000000001', CURRENT_DATE - 1);

UPDATE membro SET status = 'DESATIVADO' WHERE id = '10000000-0000-4000-8000-000000000007';
INSERT INTO auditoria (id, organizacao_id, administrador_id, acao, entidade, entidade_id, justificativa) VALUES
  (gen_random_uuid(), 'a0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001',
   'DESATIVACAO_MEMBRO', 'membro', '10000000-0000-4000-8000-000000000007', 'Solicitação do associado.');

-- Plano desativado: o membro já vinculado continua normalmente (RF04)
UPDATE plano_associacao SET status = 'INATIVO' WHERE id = 'd0000000-0000-4000-8000-000000000004';
INSERT INTO auditoria (id, organizacao_id, administrador_id, acao, entidade, entidade_id, justificativa) VALUES
  (gen_random_uuid(), 'a0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001',
   'EDICAO_PLANO', 'plano_associacao', 'd0000000-0000-4000-8000-000000000004', 'Plano encerrado para novas adesões.');

-- -----------------------------------------------------------------------------
-- Check-ins aprovados e rejeitados (RF10)
-- -----------------------------------------------------------------------------
INSERT INTO check_in (id, carteirinha_id, unidade_evento_id, operador_id, data_hora, resultado)
SELECT gen_random_uuid(), c.id, v.unidade, v.operador, now() - v.quando, v.resultado::resultado_check_in
  FROM (VALUES
    ('10000000-0000-4000-8000-000000000001'::uuid, 'f0000000-0000-4000-8000-000000000001'::uuid, 'c0000000-0000-4000-8000-000000000001'::uuid, interval '4 days',  'APROVADO'),
    ('10000000-0000-4000-8000-000000000001'::uuid, 'f0000000-0000-4000-8000-000000000001'::uuid, 'c0000000-0000-4000-8000-000000000001'::uuid, interval '2 days',  'APROVADO'),
    ('10000000-0000-4000-8000-000000000005'::uuid, 'f0000000-0000-4000-8000-000000000002'::uuid, 'c0000000-0000-4000-8000-000000000001'::uuid, interval '1 day',   'APROVADO'),
    ('10000000-0000-4000-8000-000000000002'::uuid, 'f0000000-0000-4000-8000-000000000002'::uuid, 'c0000000-0000-4000-8000-000000000001'::uuid, interval '1 day',   'REJEITADO_PLANO_NAO_ACEITO'),
    ('10000000-0000-4000-8000-000000000003'::uuid, 'f0000000-0000-4000-8000-000000000001'::uuid, 'c0000000-0000-4000-8000-000000000001'::uuid, interval '3 hours', 'REJEITADO_CARTEIRINHA_VENCIDA'),
    ('10000000-0000-4000-8000-000000000004'::uuid, 'f0000000-0000-4000-8000-000000000001'::uuid, 'c0000000-0000-4000-8000-000000000001'::uuid, interval '2 hours', 'REJEITADO_CARTEIRINHA_BLOQUEADA'),
    ('10000000-0000-4000-8000-000000000009'::uuid, 'f0000000-0000-4000-8000-000000000004'::uuid, 'c0000000-0000-4000-8000-000000000003'::uuid, interval '1 hour',  'APROVADO')
  ) AS v(membro, unidade, operador, quando, resultado)
  JOIN carteirinha c ON c.membro_id = v.membro;

-- Tentativa com QR Code inválido: não corresponde a nenhuma carteirinha
INSERT INTO check_in (id, carteirinha_id, unidade_evento_id, operador_id, data_hora, resultado) VALUES
  (gen_random_uuid(), NULL, 'f0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001', now() - interval '30 minutes', 'REJEITADO_QR_INVALIDO');

COMMIT;
