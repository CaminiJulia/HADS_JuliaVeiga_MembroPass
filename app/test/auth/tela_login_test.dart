import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/auth/auth_repositorio_simulado.dart';
import 'package:membropass/main.dart';

void main() {
  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(MembroPassApp(repositorio: AuthRepositorioSimulado(atraso: Duration.zero)));
    await tester.tap(find.byKey(const Key('botao-entrar-com-email')));
    await tester.pumpAndSettle();
  }

  /// A tela de teste é pequena (800x600); rola até o botão antes de tocar.
  Future<void> tocarEmEntrar(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('botao-entrar')));
    await tester.tap(find.byKey(const Key('botao-entrar')));
    await tester.pumpAndSettle();
  }

  Future<void> preencherEEntrar(WidgetTester tester, {required String email, required String senha}) async {
    await tester.enterText(find.byKey(const Key('campo-email')), email);
    await tester.enterText(find.byKey(const Key('campo-senha')), senha);
    await tocarEmEntrar(tester);
  }

  testWidgets('mostra os erros de validação quando os campos estão vazios', (tester) async {
    await abrirApp(tester);
    await tocarEmEntrar(tester);

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('mostra mensagem clara quando a senha está errada (HU02)', (tester) async {
    await abrirApp(tester);
    await preencherEEntrar(tester, email: 'membro@membropass.dev', senha: 'errada');

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(find.text('Acesse sua conta'), findsOneWidget);
  });

  for (final (email, destino) in [
    ('admin@membropass.dev', 'Painel da organização'),
    ('operador@membropass.dev', 'Leitura de QR Code'),
    ('membro@membropass.dev', 'Carteirinha digital'),
  ]) {
    testWidgets('leva $email para "$destino" (RF01)', (tester) async {
      await abrirApp(tester);
      await preencherEEntrar(tester, email: email, senha: AuthRepositorioSimulado.senhaDeTeste);

      expect(find.text(destino), findsOneWidget);
      expect(find.text('Acesse sua conta'), findsNothing);
    });
  }

  testWidgets('o app abre nas boas-vindas', (tester) async {
    await tester.pumpWidget(MembroPassApp(repositorio: AuthRepositorioSimulado(atraso: Duration.zero)));

    expect(find.text('Boas-vindas!'), findsOneWidget);
    expect(find.text('Acesse sua conta'), findsNothing);
  });

  testWidgets('voltar no login retorna para as boas-vindas', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Boas-vindas!'), findsOneWidget);
  });

  testWidgets('sair volta para as boas-vindas, sem caminho de volta para a área', (tester) async {
    await abrirApp(tester);
    await preencherEEntrar(tester, email: 'membro@membropass.dev', senha: AuthRepositorioSimulado.senhaDeTeste);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Boas-vindas!'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('mostrar senha alterna a visibilidade do campo', (tester) async {
    await abrirApp(tester);
    bool senhaOculta() => tester.widget<EditableText>(
      find.descendant(of: find.byKey(const Key('campo-senha')), matching: find.byType(EditableText)),
    ).obscureText;

    expect(senhaOculta(), isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(senhaOculta(), isFalse);
  });
}
