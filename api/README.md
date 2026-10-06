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
npm run start:dev
```

A API sobe em `http://localhost:3000`.

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

## Variáveis de ambiente

Veja [`.env.example`](.env.example). O arquivo `.env` não é versionado.
