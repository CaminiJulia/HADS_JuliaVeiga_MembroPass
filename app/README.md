# 📱 MembroPass — App

Aplicativo do MembroPass em **Flutter**. Um único código atende os três perfis: a navegação e as
telas mudam conforme o papel do usuário autenticado.

| Perfil | Telas principais |
|---|---|
| Membro | Carteirinha digital com QR Code, benefícios do plano |
| Operador | Leitura do QR Code e resultado do check-in |
| Administrador da organização | Painel com planos, membros, benefícios, unidades, identidade visual e auditoria |

## Executando

Com a API rodando (veja [`../api/README.md`](../api/README.md)):

```bash
flutter pub get
flutter run
```

> No emulador Android, a API local fica acessível em `http://10.0.2.2:3000`, o endereço padrão do
> app. Em um celular físico, informe o IP do computador:
> `flutter run --dart-define=API_URL=http://192.168.0.10:3000/api`

Para entrar, use as contas dos dados de teste listadas em [`../api/README.md`](../api/README.md#autenticação).

## Estrutura

```
lib/
├── main.dart     # Escolhe a tela inicial conforme o papel do usuário logado
├── config.dart   # Endereço da API
├── tema.dart     # Tema na cor da organização (white-label)
├── core/         # Cliente HTTP da API
├── auth/         # Login, sessão (Riverpod) e armazenamento seguro do token
└── areas/        # Área do administrador, do operador e do membro
```

## Testes

```bash
flutter test
```
