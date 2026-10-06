# Convenções do Projeto

## Mensagens de commit

Formato: `tipo(escopo): descrição curta no imperativo`

| Tipo | Uso |
|---|---|
| `feat` | Nova funcionalidade |
| `fix` | Correção de erro |
| `docs` | Documentação (DVP, diagramas, README, status) |
| `test` | Testes |
| `db` | Banco de dados: schema, migrations, scripts SQL |
| `refactor` | Melhoria de código sem mudar comportamento |
| `chore` | Configuração, dependências, ferramentas |

Escopos: `api`, `app`, `database`, `docs`.

Exemplos:

```
feat(api): cadastro de planos de associação (RF04)
feat(app): tela da carteirinha digital (RF05)
db(database): trigger de auditoria imutável (RF16)
docs: status da semana 3
```

Sempre que possível, cite o requisito do DVP (RF/RNF) na mensagem.

## Entregas semanais

Toda segunda-feira (TDE):

1. Atualizar o [`STATUS.md`](STATUS.md) com o que foi feito na semana.
2. Atualizar a coluna de status do cronograma no [`README.md`](../README.md).
3. Fazer commit e marcar a entrega com uma tag:

```bash
git tag semana-N
git push origin main --tags
```

## Branches

- `main`: versão estável, entregue ao professor.
- `feat/<nome>`: desenvolvimento de cada funcionalidade, juntada à `main` quando estiver funcionando.
