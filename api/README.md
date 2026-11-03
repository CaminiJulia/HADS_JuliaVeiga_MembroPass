# MembroPass — API

API REST em [NestJS](https://nestjs.com) com PostgreSQL acessado por SQL puro (biblioteca `pg`).
Como executar: veja o [README principal](../README.md#-como-executar).

## Rotas

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| `GET` | `/saude` | livre | Confere se a API está no ar e falando com o banco |
| `POST` | `/auth/login` | livre | Login (RF01). Devolve o token JWT e os dados do usuário. Bloqueia o e-mail por 1 min após 5 erros |
| `POST` | `/auth/recuperar-senha` | livre | Recuperação de senha (HU03). Ainda não envia e-mail |
| `GET` | `/planos` | administrador | Lista os planos da organização (RF04) |
| `POST` | `/planos` | administrador | Cria um plano |
| `PUT` | `/planos/:id` | administrador | Edita nome, valor de referência e duração |
| `PATCH` | `/planos/:id/status` | administrador | Ativa ou desativa (`{"status": "ATIVO" \| "INATIVO"}`) |

As rotas protegidas exigem o cabeçalho `Authorization: Bearer <token>`. A organização vem do token,
então cada usuário só enxerga os dados da própria organização.

## Estrutura

```
api/
├── database/
│   ├── 01_criacao.sql       # tabelas, tipos e índices
│   └── 02_dados_teste.sql   # organização, contas e planos de teste
├── scripts/recriar-banco.mjs  # npm run db:recriar
└── src/
    ├── banco/    # pool de conexões do pg
    ├── auth/     # login, JWT, guarda de papel e limite de tentativas
    └── planos/   # RF04
```

## Comandos

```bash
npm run start:dev   # API com recarga automática
npm run db:recriar  # apaga e recria o banco a partir de database/
npm test            # testes unitários
npm run lint        # verificação do código
```
