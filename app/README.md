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

> No emulador Android, a API local fica acessível em `http://10.0.2.2:3000`.

## Testes

```bash
flutter test
```
