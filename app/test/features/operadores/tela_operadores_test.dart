import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/features/operadores/data/operadores_repositorio.dart';

import '../../ajuda.dart';

void main() {
  Future<void> abrirOperadores(WidgetTester tester) => entrarComoAdmin(tester, secao: 'Operadores');

  /// Abre as ações do operador de nome [nome] e toca em [acao].
  Future<void> acao(WidgetTester tester, String nome, String acao) async {
    await tester.tap(find.text(nome));
    await tester.pumpAndSettle();
    await tester.tap(find.text(acao));
    await tester.pumpAndSettle();
  }

  testWidgets('lista os operadores com a atividade do dia', (tester) async {
    await abrirOperadores(tester);

    expect(find.text('Otávio Operador'), findsOneWidget);
    expect(find.text('operador@membropass.dev'), findsOneWidget);
    expect(find.textContaining('12 leituras hoje'), findsOneWidget);
  });

  testWidgets('cadastra um operador e mostra a senha provisória', (tester) async {
    await abrirOperadores(tester);
    await tester.tap(find.byKey(const Key('botao-novo-operador')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-nome-operador')), 'Paula Portaria');
    await tester.enterText(find.byKey(const Key('campo-email-operador')), 'Paula@Clube.com');
    await tester.tap(find.byKey(const Key('botao-salvar-operador')));
    await tester.pumpAndSettle();

    expect(find.text('Paula Portaria cadastrado'), findsOneWidget);
    expect(find.text(OperadoresRepositorioMock.senhaProvisoria), findsOneWidget);
    expect(find.text('paula@clube.com'), findsOneWidget);
    expect(find.byKey(const Key('senha-enviada-por-email')), findsOneWidget);

    await tester.tap(find.text('Pronto'));
    await tester.pumpAndSettle();
    expect(find.text('Paula Portaria'), findsOneWidget);
    expect(find.text('Ainda não fez leituras'), findsOneWidget);
  });

  testWidgets('valida o formulário e avisa e-mail já usado', (tester) async {
    await abrirOperadores(tester);
    await tester.tap(find.byKey(const Key('botao-novo-operador')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('botao-salvar-operador')));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome do operador.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo-nome-operador')), 'Outro');
    await tester.enterText(find.byKey(const Key('campo-email-operador')), 'membro@membropass.dev');
    await tester.tap(find.byKey(const Key('botao-salvar-operador')));
    await tester.pumpAndSettle();
    expect(find.text('Este e-mail já está em uso por outra conta.'), findsOneWidget);
    expect(find.text('Novo operador'), findsOneWidget); // continua no formulário
  });

  testWidgets('edita os dados de um operador', (tester) async {
    await abrirOperadores(tester);
    await acao(tester, 'Otávio Operador', 'Editar dados');

    await tester.enterText(find.byKey(const Key('campo-nome-operador')), 'Otávio Silva');
    await tester.tap(find.byKey(const Key('botao-salvar-operador')));
    await tester.pumpAndSettle();
    expect(find.text('Otávio Silva'), findsOneWidget);
    expect(find.text('Dados de Otávio Silva atualizados.'), findsOneWidget);
  });

  testWidgets('gera nova senha provisória com confirmação', (tester) async {
    await abrirOperadores(tester);
    await acao(tester, 'Otávio Operador', 'Gerar nova senha provisória');

    await tester.tap(find.text('Gerar senha'));
    await tester.pumpAndSettle();
    expect(find.text('Nova senha de Otávio Operador'), findsOneWidget);
    expect(find.text(OperadoresRepositorioMock.senhaProvisoria), findsOneWidget);
  });

  testWidgets('desativa e reativa o acesso', (tester) async {
    await abrirOperadores(tester);
    await acao(tester, 'Otávio Operador', 'Desativar acesso');
    await tester.tap(find.text('Desativar'));
    await tester.pumpAndSettle();
    expect(find.text('Inativo'), findsOneWidget);

    await acao(tester, 'Otávio Operador', 'Reativar acesso');
    await tester.tap(find.text('Reativar'));
    await tester.pumpAndSettle();
    expect(find.text('Inativo'), findsNothing);
  });
}
