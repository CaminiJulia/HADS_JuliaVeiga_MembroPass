# MembroPass — API

API REST em [NestJS](https://nestjs.com) com PostgreSQL acessado por SQL puro (biblioteca `pg`).
Como executar: veja o [README principal](../README.md#-como-executar).

## Rotas

As rotas protegidas exigem o cabeçalho `Authorization: Bearer <token>`. A organização vem do token,
então cada usuário só enxerga e altera os dados da própria organização.

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| `GET` | `/saude` | livre | Confere se a API está no ar e falando com o banco |
| `POST` | `/auth/login` | livre | Login (RF01). Devolve o token JWT e os dados do usuário. Bloqueia o e-mail por 1 min após 5 erros |
| `POST` | `/auth/recuperar-senha` | livre | Recuperação de senha (HU03). Ainda não envia e-mail |
| `GET` | `/organizacao` | todos | Nome e identidade visual da organização (RF17) |
| `PUT` | `/organizacao/identidade` | admin | Cor (contraste mínimo 4,5:1) e logo em base64 (até 512 KB) |
| `GET` `POST` | `/planos` | admin | Listar e criar planos (RF04) |
| `PUT` | `/planos/:id` | admin | Editar nome, valor, duração e cor (registrado na auditoria) |
| `PATCH` | `/planos/:id/status` | admin | Ativar ou desativar |
| `GET` `POST` | `/beneficios` | admin | Listar e criar benefícios (RF08) |
| `PUT` `DELETE` | `/beneficios/:id` | admin | Editar (inclusive o logo do parceiro, em base64, até 256 KB) e excluir |
| `GET` `POST` | `/membros` | admin | Listar (`?busca=`) e cadastrar membros (RF06). O cadastro devolve a senha provisória |
| `GET` `PUT` | `/membros/:id` | admin | Detalhe e edição |
| `PATCH` | `/membros/:id/status` | admin | Desativar ou reativar, com justificativa opcional |
| `POST` | `/membros/:id/liberar-ciclo` | admin | Confirma o pagamento e libera o novo ciclo (RF07) |
| `POST` | `/membros/:id/bloquear` | admin | Bloqueio manual, com justificativa obrigatória |
| `POST` | `/membros/:id/desbloquear` | admin | Desbloqueio |
| `GET` | `/membros/:id/historico` | admin | Auditoria do membro |
| `GET` `POST` | `/unidades-eventos` | admin | Listar e criar unidades e eventos (RF11) |
| `PUT` `DELETE` | `/unidades-eventos/:id` | admin | Editar e excluir |
| `GET` | `/auditoria` | admin | Últimas 200 ações da organização (RF16) |

## Banco de dados

Os scripts de `database/` rodam em ordem com `npm run db:recriar`:

| Script | Conteúdo |
|---|---|
| `01_criacao.sql` | Tipos, tabelas, restrições e índices |
| `02_regras_negocio.sql` | Triggers e funções: e-mail único entre os três cadastros, emissão automática da carteirinha, plano da mesma organização do membro, auditoria imutável e `liberar_ciclo()` |
| `03_dados_teste.sql` | Organização, contas, planos, membros, benefícios, unidade e evento de teste |

## Estrutura

```
api/
├── database/                 # scripts SQL (acima)
├── scripts/recriar-banco.mjs # npm run db:recriar
└── src/
    ├── banco/        # pool de conexões do pg e transações
    ├── auth/         # login, JWT, guarda de papel e limite de tentativas
    ├── auditoria/    # registro e consulta da auditoria
    ├── organizacao/  # identidade visual e cálculo de contraste
    ├── planos/       # RF04 e vínculo N:M com planos
    ├── beneficios/   # RF08
    ├── membros/      # RF05, RF06 e RF07
    └── unidades/     # RF11
```

## Comandos

```bash
npm run start:dev   # API com recarga automática
npm run db:recriar  # apaga e recria o banco a partir de database/
npm test            # testes unitários
npm run lint        # verificação do código
```
