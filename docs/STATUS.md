# Status Semanal — MembroPass

## Semana 2 (entrega 12/10)

**Concluído**
- Modelo do banco no Prisma com as 13 tabelas do modelo lógico v2.6
- Migrations de criação das tabelas e de regras de negócio
- Scripts SQL em `database/`: criação, dados de teste, triggers e procedures
  - 8 triggers: e-mail único entre cadastros, emissão e invalidação de carteirinha, isolamento entre
    organizações, auditoria imutável
  - 2 procedures: liberação de ciclo e bloqueio manual, ambas com registro em auditoria
  - View de situação dos membros e função de cálculo de vencimento
- Dados de teste com todos os cenários: carteirinha ativa, vencendo, vencida, bloqueada e invalidada;
  check-ins aprovados e rejeitados; segunda organização para testar o isolamento
- Esqueleto da API: conexão com o banco, validação global de entrada, endpoint `GET /api/saude`
- Regras de domínio da carteirinha com 13 testes unitários
- Primeiro teste funcional (endpoint de saúde)
- Prisma fixado na versão estável 7.10.0

**Verificação**
- 13 cenários testados direto no banco, 12 deles tentando violar as regras. Todos foram bloqueados
  com mensagem clara
- Banco recriado do zero com migrations e dados de teste, com resultado idêntico

**Próxima semana (19/10)**
- Login e perfis (RF01, RF02) na API e no app, com navegação por papel

**Pendências no DVP**
- Incluir diagrama de classes e diagrama de componentes
- Trocar Jest por Vitest na tabela de ferramentas (o projeto usa Vitest)
- Incluir a definição do MVP e o novo cronograma
- Modelo lógico: incluir `beneficio.tipo_desconto` (percentual ou valor, exigido pelo RF08)
- Modelo lógico: `check_in.carteirinha_id` passa a ser opcional (tentativa com QR inválido não tem
  carteirinha); `resultado` guarda o motivo da rejeição
- Descrever triggers, procedures e view na seção do banco de dados

---

## Semana 1 (entrega 05/10)

**Concluído**
- Definição do MVP (`docs/MVP.md`)
- Cronograma de implementação alinhado ao Plano de Ensino (`docs/CRONOGRAMA.md`)
- Estrutura do repositório: `api/` (NestJS), `app/` (Flutter), `database/`, `docs/`
- DVP v2.6 versionado em `docs/dvp/`
- PostgreSQL via Docker Compose
