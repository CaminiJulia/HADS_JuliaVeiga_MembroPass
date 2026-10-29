import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/app.dart';
import 'package:membropass/features/auth/data/auth_repositorio_mock.dart';

void main() {
  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MembroPassApp(authRepositorio: AuthRepositorioMock(latencia: Duration.zero)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> entrar(WidgetTester tester, String email, String senha) async {
    await tester.enterText(find.byKey(const Key('campo-email')), email);
    await tester.enterText(find.byKey(const Key('campo-senha')), senha);
    await tester.ensureVisible(find.byKey(const Key('botao-entrar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-entrar')));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra erros de validação com campos vazios', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.byKey(const Key('botao-entrar')));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('mostra mensagem genérica com senha incorreta', (tester) async {
    await abrirApp(tester);
    await entrar(tester, 'admin@membropass.dev', 'errada');

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });

  testWidgets('bloqueia após 5 tentativas incorretas', (tester) async {
    await abrirApp(tester);
    for (var i = 0; i < 5; i++) {
      await entrar(tester, 'admin@membropass.dev', 'errada');
    }

    expect(find.textContaining('Muitas tentativas sem sucesso'), findsOneWidget);

    // Mesmo com a senha certa, continua bloqueado durante o período.
    await entrar(tester, 'admin@membropass.dev', AuthRepositorioMock.senhaPadrao);
    expect(find.textContaining('Muitas tentativas sem sucesso'), findsOneWidget);
  });

  for (final (email, tituloArea) in [
    ('admin@membropass.dev', 'Painel da organização'),
    ('operador@membropass.dev', 'Validar check-in'),
    ('membro@membropass.dev', 'Minha carteirinha'),
  ]) {
    testWidgets('redireciona $email para "$tituloArea"', (tester) async {
      await abrirApp(tester);
      await entrar(tester, email, AuthRepositorioMock.senhaPadrao);

      expect(find.text(tituloArea), findsOneWidget);
    });
  }

  testWidgets('abre a recuperação de senha com o e-mail já preenchido', (tester) async {
    await abrirApp(tester);
    await tester.enterText(find.byKey(const Key('campo-email')), 'ana@org.com');
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar senha'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'ana@org.com'), findsOneWidget);

    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();
    expect(find.text('Verifique seu e-mail'), findsOneWidget);
  });
}
