# MembroPass

Plataforma white-label de carteirinha digital para programas de associados: as organizações gerenciam
planos, membros e ciclos, os membros apresentam a carteirinha com QR Code e os operadores registram o
check-in nas unidades e eventos.

Trabalho final de **HADS022 – Laboratório de Desenvolvimento de Sistemas** (UPF, 2026/2), Grupo 1.
Autora: Julia Camini Veiga.

## Estrutura do repositório

| Pasta | Conteúdo |
|---|---|
| `api/` | API REST em Node.js + NestJS, com Prisma ORM e PostgreSQL |
| `app/` | Aplicativo Flutter (membro, operador e administrador da organização no mesmo código) |
| `database/` | Scripts SQL: criação do banco, dados de teste, triggers e procedures |
| `docs/dvp/` | Documento de Visão do Produto (DVP) |
| `docs/diagramas/` | Diagramas de casos de uso, classes, componentes e modelo lógico |
| `docs/MVP.md` | Definição do MVP |
| `docs/CRONOGRAMA.md` | Cronograma de implementação |
| `docs/STATUS.md` | Status semanal do projeto |

## Como rodar

Pré-requisitos: Node.js 22+, Flutter 3.35+ e Docker.

```bash
# 1. Banco de dados
docker compose up -d

# 2. API
cd api
npm install
npm run start:dev

# 3. App
cd app
flutter pub get
flutter run
```
