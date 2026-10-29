# MembroPass — App

Aplicativo Flutter único para os três papéis do MembroPass: membro, operador e administrador da organização.
A área exibida depende do papel de quem fez login (RF01, RF02).

## Organização do código

```
lib/
├── main.dart                          # Ponto de entrada e navegação entre as telas
├── tema.dart                          # Cores da marca e tema claro
├── auth/
│   ├── tela_boas_vindas.dart          # Primeira tela do app
│   ├── tela_login.dart                # Login único para os três papéis
│   ├── visual_entrada.dart            # Tema escuro e fundo das telas de entrada
│   ├── usuario.dart                   # Usuário e papéis
│   ├── auth_repositorio.dart          # Contrato da autenticação e erros de login
│   └── auth_repositorio_simulado.dart # Implementação provisória, até a API existir
├── areas/
│   └── area_provisoria.dart           # Destino provisório de cada papel após o login
└── core/
    └── validadores.dart               # Validações de formulário reutilizáveis (RNF16)
```

A tela de login depende só da interface `AuthRepositorio`. Quando a API estiver pronta, basta trocar
`AuthRepositorioSimulado` por uma implementação que chame a API, sem mudar a tela.

## Executar

```bash
flutter pub get
flutter run
```

Contas de teste: `admin@membropass.dev`, `operador@membropass.dev` e `membro@membropass.dev`, todas com a
senha `Senha@123`. Após 5 tentativas erradas, o e-mail fica bloqueado por 15 minutos (RF01).

> **Erro `What went wrong: 25.0.3` ao compilar para Android:** o Gradle do projeto não funciona com o Java 25
> que vem com o Android Studio mais novo. Aponte o Flutter para um JDK 17:
> `flutter config --jdk-dir="C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot"`

## Testes

```bash
flutter test
```

## Ícone e tela de abertura

Gerados a partir de `assets/marca/` pelos pacotes `flutter_launcher_icons` e `flutter_native_splash`
(configuração no `pubspec.yaml`). Depois de trocar as imagens:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
