import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/areas/area_administrador.dart';
import 'package:membropass/areas/area_membro.dart';
import 'package:membropass/areas/area_operador.dart';
import 'package:membropass/auth/auth_repositorio.dart';
import 'package:membropass/auth/sessao.dart';
import 'package:membropass/auth/tela_login.dart';
import 'package:membropass/auth/usuario.dart';
import 'package:membropass/core/api_cliente.dart';
import 'package:membropass/main.dart';

const _senha = 'Senha@123';

Usuario _usuario(Papel papel, {String status = 'HABILITADA'}) => Usuario(
      id: 'id-${papel.name}',
      papel: papel,
      nome: 'Pessoa ${papel.name}',
      email: '${papel.name}@clube.com.br',
      organizacao: Organizacao(id: 'org', nome: 'Clube Atlético', status: status, corPrincipal: '#1E3A8A'),
    );

class _RepositorioFalso implements AuthRepositorio {
  _RepositorioFalso(this.usuarios);

  final Map<String, Usuario> usuarios;

  @override
  Future<Sessao> entrar(String email, String senha) async {
    final usuario = usuarios[email];
    if (usuario == null || senha != _senha) {
      throw const ApiExcecao(401, 'E-mail ou senha inválidos.');
    }
    return Sessao(token: 'token-$email', usuario: usuario);
  }

  @override
  Future<Usuario> perfil(String token) async {
    final usuario = usuarios[token.replaceFirst('token-', '')];
    if (usuario == null) throw const ApiExcecao(401, 'Sessão inválida ou expirada.');
    return usuario;
  }
}

class _ArmazenamentoEmMemoria implements ArmazenamentoToken {
  _ArmazenamentoEmMemoria([this.token]);

  String? token;

  @override
  Future<String?> ler() async => token;

  @override
  Future<void> salvar(String token) async => this.token = token;

  @override
  Future<void> apagar() async => token = null;
}

Future<_ArmazenamentoEmMemoria> _abrirApp(
  WidgetTester tester, {
  required List<Usuario> usuarios,
  String? tokenSalvo,
}) async {
  final armazenamento = _ArmazenamentoEmMemoria(tokenSalvo);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositorioProvider.overrideWithValue(
        _RepositorioFalso({for (final u in usuarios) u.email: u}),
      ),
      armazenamentoTokenProvider.overrideWithValue(armazenamento),
    ],
    child: const MembroPassApp(),
  ));
  await tester.pumpAndSettle();
  return armazenamento;
}

Future<void> _entrar(WidgetTester tester, String email, [String senha = _senha]) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), senha);
  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  // RF02: cada papel abre a sua área depois do login.
  for (final (papel, area) in [
    (Papel.administrador, AreaAdministrador),
    (Papel.operador, AreaOperador),
    (Papel.membro, AreaMembro),
  ]) {
    testWidgets('o ${papel.name} entra e abre a sua área', (tester) async {
      final usuario = _usuario(papel);
      final armazenamento = await _abrirApp(tester, usuarios: [usuario]);

      expect(find.byType(TelaLogin), findsOneWidget);
      await _entrar(tester, usuario.email);

      expect(find.byType(area), findsOneWidget);
      expect(find.text('Clube Atlético'), findsOneWidget);
      expect(armazenamento.token, 'token-${usuario.email}');
    });
  }

  testWidgets('mostra a mensagem da API quando o login falha', (tester) async {
    await _abrirApp(tester, usuarios: [_usuario(Papel.membro)]);

    await _entrar(tester, 'membro@clube.com.br', 'senha-errada');

    expect(find.byType(TelaLogin), findsOneWidget);
    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
  });

  testWidgets('valida os campos antes de chamar a API', (tester) async {
    await _abrirApp(tester, usuarios: []);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);
  });

  testWidgets('restaura a sessão salva ao abrir o app', (tester) async {
    final operador = _usuario(Papel.operador);
    await _abrirApp(tester, usuarios: [operador], tokenSalvo: 'token-${operador.email}');

    expect(find.byType(AreaOperador), findsOneWidget);
  });

  testWidgets('descarta o token salvo que não vale mais', (tester) async {
    final armazenamento = await _abrirApp(tester, usuarios: [], tokenSalvo: 'token-expirado');

    expect(find.byType(TelaLogin), findsOneWidget);
    expect(armazenamento.token, isNull);
  });

  testWidgets('sair apaga a sessão e volta ao login', (tester) async {
    final membro = _usuario(Papel.membro);
    final armazenamento = await _abrirApp(tester, usuarios: [membro]);
    await _entrar(tester, membro.email);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaLogin), findsOneWidget);
    expect(armazenamento.token, isNull);
  });

  testWidgets('administrador de organização em habilitação vê só o aviso (RF03)', (tester) async {
    final admin = _usuario(Papel.administrador, status: 'EM_HABILITACAO');
    await _abrirApp(tester, usuarios: [admin]);
    await _entrar(tester, admin.email);

    expect(find.textContaining('em habilitação'), findsOneWidget);
  });
}
