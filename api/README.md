# ⚙️ MembroPass — API

API REST do MembroPass, construída com **NestJS**, **Prisma ORM** e **PostgreSQL**.

## Responsabilidades

- Autenticação e controle de acesso por papel (administrador, operador e membro)
- Isolamento de dados entre organizações (multi-tenant)
- Regras de negócio: cálculo de vencimento, liberação de ciclo, bloqueio manual e auditoria
- Geração e validação do QR Code assinado da carteirinha

## Executando

Com o banco rodando (`docker compose up -d` na raiz do repositório):

```bash
cp .env.example .env
npm install
npx prisma migrate deploy
npm run db:seed
npm run start:dev
```

A API sobe em `http://localhost:3000/api`. Para conferir: `GET /api/saude`.

## Estrutura

```
src/
├── auth/         # Login, perfis e guards de acesso por papel e organização
├── domain/       # Regras de domínio puras, cobertas por testes unitários
├── prisma/       # Conexão com o banco (PrismaService)
├── saude/        # Endpoint de verificação da API
└── generated/    # Cliente gerado pelo Prisma (não versionado)
prisma/
├── schema.prisma # Modelo lógico do banco (DVP v2.6)
└── migrations/   # Criação das tabelas e regras de negócio em SQL
test/             # Testes funcionais dos endpoints
```

## Autenticação

| Rota | Acesso | Descrição |
|---|---|---|
| `POST /api/auth/login` | Público | Login por e-mail e senha; devolve o token e o perfil |
| `GET /api/auth/eu` | Os três papéis | Perfil de quem está logado |

As demais rotas exigem o cabeçalho `Authorization: Bearer <token>` e declaram os papéis autorizados
com `@Papeis()`. Rota sem esse decorator é negada (veja `src/auth/guards/`). O `organizacaoId` de
quem está logado vem em `@UsuarioAtual()` e deve filtrar toda consulta (multi-tenant).

Contas dos dados de teste (senha `Senha@123`): `admin@clubeatletico.com.br` (administrador),
`portaria@clubeatletico.com.br` (operador), `ana.souza@email.com` (membro) e
`admin@acnorte.com.br` (administrador de organização em habilitação).

Os testes funcionais (`npm run test:e2e`) recriam o banco `membropass_test` no mesmo servidor do
`.env`, com as migrations e os dados de teste. O banco do `.env` não é alterado.

## Scripts

| Comando | Descrição |
|---|---|
| `npm run start:dev` | Executa em modo de desenvolvimento, com recarga automática |
| `npm run build` | Gera a versão de produção em `dist/` |
| `npm test` | Testes unitários |
| `npm run test:e2e` | Testes funcionais dos endpoints |
| `npm run test:cov` | Testes com relatório de cobertura |
| `npm run lint` | Análise estática do código |
| `npm run format` | Formata o código com Prettier |
| `npm run db:migrate` | Cria uma nova migration a partir do `schema.prisma` |
| `npm run db:seed` | Insere os dados de teste |
| `npm run db:reset` | Apaga o banco e recria com os dados de teste |
| `npm run db:sql` | Atualiza os scripts SQL da pasta `database/` |

## Variáveis de ambiente

Veja [`.env.example`](.env.example). O arquivo `.env` não é versionado.
