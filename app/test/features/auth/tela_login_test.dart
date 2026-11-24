import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/app.dart';
import 'package:membropass/features/auth/data/auth_repositorio_mock.dart';
import 'package:membropass/repositorios.dart';

void main() {
  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(MembroPassApp(repositorios: Repositorios.simulados()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-entrar-com-email')));
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
    ('admin@membropass.dev', 'Clube Exemplo'),
    ('operador@membropass.dev', 'Validar check-in'),
    ('membro@membropass.dev', 'Marina Membro'),
  ]) {
    testWidgets('redireciona $email para "$tituloArea"', (tester) async {
      await abrirApp(tester);
      await entrar(tester, email, AuthRepositorioMock.senhaPadrao);

      expect(find.text(tituloArea), findsOneWidget);
    });
  }

  testWidgets('recupera a senha com o código do e-mail e entra com a nova', (tester) async {
    await abrirApp(tester);
    await tester.enterText(find.byKey(const Key('campo-email')), 'admin@membropass.dev');
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar senha'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'admin@membropass.dev'), findsOneWidget);
    await tester.tap(find.byKey(const Key('botao-enviar-codigo')));
    await tester.pumpAndSettle();
    expect(find.text('Digite o código'), findsOneWidget);

    // Código errado: a mensagem da API aparece e continua na mesma etapa.
    await tester.enterText(find.byKey(const Key('campo-codigo')), '000000');
    await tester.enterText(find.byKey(const Key('campo-nova-senha')), 'NovaSenha1');
    await tester.enterText(find.byKey(const Key('campo-confirmar-senha')), 'NovaSenha1');
    await tester.ensureVisible(find.byKey(const Key('botao-redefinir-senha')));
    await tester.tap(find.byKey(const Key('botao-redefinir-senha')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Código incorreto'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo-codigo')), AuthRepositorioMock.codigo);
    await tester.ensureVisible(find.byKey(const Key('botao-redefinir-senha')));
    await tester.tap(find.byKey(const Key('botao-redefinir-senha')));
    await tester.pumpAndSettle();
    expect(find.text('Senha alterada'), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao-voltar-login')));
    await tester.pumpAndSettle();
    await entrar(tester, 'admin@membropass.dev', 'NovaSenha1');
    expect(find.text('Clube Exemplo'), findsOneWidget);
  });

  testWidgets('a senha nova da recuperação segue as regras', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo-email-recuperar')), 'admin@membropass.dev');
    await tester.tap(find.byKey(const Key('botao-enviar-codigo')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-codigo')), '12');
    await tester.enterText(find.byKey(const Key('campo-nova-senha')), 'curta');
    await tester.enterText(find.byKey(const Key('campo-confirmar-senha')), 'outra');
    await tester.ensureVisible(find.byKey(const Key('botao-redefinir-senha')));
    await tester.tap(find.byKey(const Key('botao-redefinir-senha')));
    await tester.pumpAndSettle();
    expect(find.text('O código tem 6 números.'), findsOneWidget);
    expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
    expect(find.text('As senhas não conferem.'), findsOneWidget);
  });

  testWidgets('com senha provisória, pede uma senha nova antes de entrar', (tester) async {
    await abrirApp(tester);
    await entrar(tester, AuthRepositorioMock.novoOperador.email, AuthRepositorioMock.senhaProvisoria);

    expect(find.text('Crie sua senha, Paula'), findsOneWidget);
    expect(find.text('Validar check-in'), findsNothing);

    await tester.enterText(find.byKey(const Key('campo-nova-senha')), 'MinhaSenha8');
    await tester.enterText(find.byKey(const Key('campo-confirmar-senha')), 'MinhaSenha8');
    await tester.ensureVisible(find.byKey(const Key('botao-criar-senha')));
    await tester.tap(find.byKey(const Key('botao-criar-senha')));
    await tester.pumpAndSettle();
    expect(find.text('Validar check-in'), findsOneWidget);
  });

  testWidgets('a senha provisória deixa de valer depois da troca', (tester) async {
    await abrirApp(tester);
    await entrar(tester, AuthRepositorioMock.novoOperador.email, AuthRepositorioMock.senhaProvisoria);
    await tester.enterText(find.byKey(const Key('campo-nova-senha')), 'MinhaSenha8');
    await tester.enterText(find.byKey(const Key('campo-confirmar-senha')), 'MinhaSenha8');
    await tester.ensureVisible(find.byKey(const Key('botao-criar-senha')));
    await tester.tap(find.byKey(const Key('botao-criar-senha')));
    await tester.pumpAndSettle();

    // Sai e tenta a provisória de novo: não entra. Com a nova, vai direto.
    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-entrar-com-email')));
    await tester.pumpAndSettle();
    await entrar(tester, AuthRepositorioMock.novoOperador.email, AuthRepositorioMock.senhaProvisoria);
    expect(find.textContaining('incorretos'), findsOneWidget);
    await entrar(tester, AuthRepositorioMock.novoOperador.email, 'MinhaSenha8');
    expect(find.text('Validar check-in'), findsOneWidget);
    expect(find.text('Crie sua senha, Paula'), findsNothing);
  });
}
