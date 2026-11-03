# MembroPass — App

Aplicativo Flutter com as áreas do administrador, do operador e do membro.
Como executar: veja o [README principal](../README.md#-como-executar).

## Estrutura

```
lib/
├── core/
│   ├── api/          # cliente HTTP da API (guarda e envia o token)
│   ├── formatacao/   # valores em reais
│   ├── tema/         # cores e tema da marca
│   └── validacao/    # validadores de formulário
└── features/
    ├── auth/         # boas-vindas, login e recuperação de senha
    ├── painel_admin/ # tela inicial do administrador
    ├── planos/       # RF04
    └── areas/        # telas provisórias do operador e do membro
```

Cada funcionalidade separa `domain/` (modelos e contratos), `data/` (implementação pela API e versão
simulada para os testes) e `presentation/` (telas).

## Testes

```bash
flutter test
```

Os testes usam os repositórios simulados (`*_mock.dart`), então não precisam da API rodando.
