# 🐘 Banco de Dados

Scripts SQL do MembroPass (PostgreSQL 17), conforme o item 2.1 do Plano de Ensino.

| Script | Conteúdo |
|---|---|
| [`01_criacao.sql`](01_criacao.sql) | Criação dos tipos, tabelas, chaves e índices (modelo lógico do DVP v2.6) |
| [`02_dados_teste.sql`](02_dados_teste.sql) | Dados para testes com cenários de todas as situações de carteirinha |
| [`03_regras_negocio.sql`](03_regras_negocio.sql) | Restrições, funções, triggers, procedures e views |

Os scripts `01` e `03` são gerados a partir das migrations do Prisma (`api/prisma/migrations/`) com
`npm run db:sql`, para que o banco da API e os scripts entregues sejam sempre iguais.

## Como criar o banco

Na pasta `api/`, com o PostgreSQL rodando (`docker compose up -d` na raiz):

```bash
npx prisma migrate deploy   # executa 01 e 03
npm run db:seed             # executa 02
```

Para apagar tudo e recriar com os dados de teste: `npm run db:reset`.

## Regras de negócio no banco

### Triggers

| Trigger | Regra | Requisito |
|---|---|---|
| `trg_*_email_unico` | Um e-mail não pode existir em mais de um dos três cadastros (administrador, operador, membro) | RF01 |
| `trg_membro_validar_plano` | O plano do membro deve ser da mesma organização e estar ativo no vínculo | RNF01, HU07 |
| `trg_membro_emitir_carteirinha` | Emite a carteirinha ao cadastrar o membro, com vencimento = adesão + duração do plano | RF05 |
| `trg_membro_invalidar_carteirinha` | Invalida a carteirinha quando o membro é desativado ou cancelado | RF06 |
| `trg_plano_beneficio_mesma_organizacao` | Plano e benefício vinculados devem ser da mesma organização | RNF01 |
| `trg_unidade_evento_plano_mesma_organizacao` | Unidade/evento e plano aceito devem ser da mesma organização | RNF01 |
| `trg_check_in_mesma_organizacao` | O operador só registra check-in em unidades da sua organização | RNF01, RF10 |
| `trg_auditoria_imutavel` | Registros de auditoria não podem ser alterados nem excluídos | RNF11 |

### Procedures

| Procedure | O que faz | Requisito |
|---|---|---|
| `sp_liberar_ciclo(membro, administrador, data_referencia)` | Confirma o pagamento, calcula o novo vencimento, reativa a carteirinha, muda a versão do QR Code e grava auditoria | RF07, HU10 |
| `sp_bloquear_carteirinha(membro, administrador, justificativa)` | Bloqueia manualmente a carteirinha, muda a versão do QR Code e grava auditoria | RF07, HU11 |

As duas validam que o administrador está ativo e pertence à mesma organização do membro.

### Funções e views

| Objeto | Descrição |
|---|---|
| `fn_situacao_carteirinha` | Calcula a situação exibida: ativa, vencendo (até 7 dias), vencida, bloqueada ou invalidada |
| `vw_situacao_membros` | Situação de todos os membros, para o acompanhamento de vencimentos (HU12, RF15) |

### Restrições (CHECK)

CNPJ com 14 dígitos · cor em hexadecimal (`#RRGGBB`) · duração do plano maior que zero · desconto
percentual até 100% · vigência e datas de evento coerentes · evento com data de início e fim.

## Dados de teste

Senha de todos os usuários: `Senha@123`

| Perfil | E-mail | Organização |
|---|---|---|
| Administrador | `admin@clubeatletico.com.br` | Clube Atlético Passo Fundo |
| Administrador | `admin@academiamovimento.com.br` | Academia Movimento |
| Operador | `portaria@clubeatletico.com.br` | Clube Atlético Passo Fundo |
| Operador | `recepcao@academiamovimento.com.br` | Academia Movimento |
| Membro | `ana.souza@email.com` | Clube Atlético (carteirinha ativa) |
| Membro | `bruno.lima@email.com` | Clube Atlético (vencendo) |
| Membro | `carla.mendes@email.com` | Clube Atlético (vencida) |
| Membro | `diego.rocha@email.com` | Clube Atlético (bloqueada) |

A organização "Associação Comercial Norte" está em habilitação, e a "Academia Movimento" serve para
testar o isolamento entre organizações.
