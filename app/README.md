# MembroPass — App

Aplicativo Flutter com as áreas do administrador, do operador e do membro.
Como executar: veja o [README principal](../README.md#-como-executar).

## Estrutura

```
lib/
├── core/
│   ├── api/          # cliente HTTP da API (guarda e envia o token)
│   ├── formatacao/   # valores em reais e datas
│   ├── tema/         # cores, tema e cálculo de contraste
│   ├── validacao/    # validadores de formulário
│   └── widgets/      # componentes comuns (avisos, selos, cartões, campo de data)
├── features/
│   ├── auth/         # boas-vindas, login e recuperação de senha
│   ├── painel_admin/ # tela inicial do administrador e contato do suporte
│   ├── planos/       # RF04
│   ├── beneficios/   # RF08
│   ├── area_membro/  # RF05 e RF09: carteirinha com QR, benefícios e locais
│   ├── membros/      # RF05, RF06 e RF07 (ciclos e bloqueios)
│   ├── auditoria/    # RF16
│   ├── unidades/     # RF11
│   ├── identidade/   # RF17
│   └── areas/        # tela provisória do operador
└── repositorios.dart # liga cada tela à API (ou às versões simuladas nos testes)
```

Cada funcionalidade separa `domain/` (modelos e contratos), `data/` (implementação pela API e versão
simulada para os testes) e `presentation/` (telas).

## Testes

```bash
flutter test
```

Os testes usam os repositórios simulados (`*_mock.dart`), então não precisam da API rodando.
O helper `test/ajuda.dart` entra como administrador e abre uma seção do painel.
