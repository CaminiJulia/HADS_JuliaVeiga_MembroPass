import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ajuda.dart';

void main() {
  Future<void> abrirPerfil(WidgetTester tester) => entrarComoAdmin(tester, secao: 'Meu perfil');

  testWidgets('o avatar do cabeçalho abre o perfil', (tester) async {
    await entrarComoAdmin(tester);
    expect(find.text('AA'), findsOneWidget); // iniciais de Ana Administradora

    await tester.tap(find.bySemanticsLabel('Meu perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('Ana Administradora'), findsWidgets); // título e campo do nome
    await rolarAte(tester, find.text('admin@membropass.dev'));
    expect(find.text('admin@membropass.dev'), findsOneWidget);
  });

  testWidgets('salva nome, cargo e telefone; o botão só habilita com mudança', (tester) async {
    await abrirPerfil(tester);

    FilledButton botao() => tester.widget<FilledButton>(find.byKey(const Key('botao-salvar-perfil')));
    expect(botao().onPressed, isNull);

    await tester.enterText(find.byKey(const Key('campo-nome-perfil')), 'Ana Souza');
    await tester.enterText(find.byKey(const Key('campo-cargo-perfil')), 'Coordenação');
    await tester.enterText(find.byKey(const Key('campo-telefone-perfil')), '(54) 99999-0000');
    await tester.pump();
    expect(botao().onPressed, isNotNull);
    // O cabeçalho do perfil acompanha a digitação.
    expect(find.text('Coordenação · Clube Exemplo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao-salvar-perfil')));
    await tester.pumpAndSettle();
    expect(find.text('Perfil atualizado.'), findsOneWidget);
    expect(botao().onPressed, isNull);

    // De volta ao painel, a saudação usa o nome novo.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Olá, Ana'), findsOneWidget);
    expect(find.text('AS'), findsOneWidget);
  });

  testWidgets('telefone inválido não salva', (tester) async {
    await abrirPerfil(tester);

    await tester.enterText(find.byKey(const Key('campo-telefone-perfil')), 'abc');
    await tester.pump();
    await tester.tap(find.byKey(const Key('botao-salvar-perfil')));
    await tester.pumpAndSettle();
    expect(find.text('Informe um telefone válido.'), findsOneWidget);
  });

  testWidgets('troca a senha e avisa quando a atual está errada', (tester) async {
    await abrirPerfil(tester);

    await rolarAte(tester, find.text('Alterar senha'));
    await tester.tap(find.text('Alterar senha'));
    await tester.pumpAndSettle();

    // Regras da nova senha e confirmação.
    await tester.enterText(find.byKey(const Key('campo-senha-atual')), 'errada');
    await tester.enterText(find.byKey(const Key('campo-nova-senha')), 'curta');
    await tester.enterText(find.byKey(const Key('campo-confirmar-senha')), 'outra');
    await tester.tap(find.byKey(const Key('botao-trocar-senha')));
    await tester.pumpAndSettle();
    expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
    expect(find.text('As senhas não conferem.'), findsOneWidget);

    // Senha atual errada: a mensagem da API aparece no diálogo.
    await tester.enterText(find.byKey(const Key('campo-nova-senha')), 'NovaSenha1');
    await tester.enterText(find.byKey(const Key('campo-confirmar-senha')), 'NovaSenha1');
    await tester.tap(find.byKey(const Key('botao-trocar-senha')));
    await tester.pumpAndSettle();
    expect(find.text('A senha atual está incorreta.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo-senha-atual')), 'Senha@123');
    await tester.tap(find.byKey(const Key('botao-trocar-senha')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('botao-trocar-senha')), findsNothing);
    expect(find.textContaining('Senha alterada'), findsOneWidget);
  });

  testWidgets('sair da conta pede confirmação e volta às boas-vindas', (tester) async {
    await abrirPerfil(tester);

    await rolarAte(tester, find.byKey(const Key('botao-sair-perfil')));
    await tester.tap(find.byKey(const Key('botao-sair-perfil')));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sair'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('botao-entrar-com-email')), findsOneWidget);
  });
}
