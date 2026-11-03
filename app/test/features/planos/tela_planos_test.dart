import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ajuda.dart';

void main() {
  Future<void> abrirPlanos(WidgetTester tester) => entrarComoAdmin(tester, secao: 'Planos');

  Future<void> preencherPlano(WidgetTester tester, String nome, String valor, String dias) async {
    await tester.enterText(find.byKey(const Key('campo-nome-plano')), nome);
    await tester.enterText(find.byKey(const Key('campo-valor-plano')), valor);
    await tester.enterText(find.byKey(const Key('campo-duracao-plano')), dias);
    await tester.tap(find.byKey(const Key('botao-salvar-plano')));
    await tester.pumpAndSettle();
  }

  testWidgets('lista os planos com valor e duração', (tester) async {
    await abrirPlanos(tester);

    expect(find.text('Mensal'), findsOneWidget);
    expect(find.text('R\$ 89,90 · ciclo de 30 dias'), findsOneWidget);
    expect(find.text('R\$ 899,00 · ciclo de 365 dias'), findsOneWidget);
  });

  testWidgets('cria um plano novo', (tester) async {
    await abrirPlanos(tester);
    await tester.tap(find.text('Novo plano'));
    await tester.pumpAndSettle();

    await preencherPlano(tester, 'Semestral', '1.479,9', '180');

    expect(find.text('Semestral'), findsOneWidget);
    expect(find.text('R\$ 1.479,90 · ciclo de 180 dias'), findsOneWidget);
  });

  testWidgets('valida o formulário e mostra nome repetido', (tester) async {
    await abrirPlanos(tester);
    await tester.tap(find.text('Novo plano'));
    await tester.pumpAndSettle();

    await preencherPlano(tester, '', '10,999', '0');
    expect(find.text('Informe o nome do plano.'), findsOneWidget);
    expect(find.text('Informe um valor válido, ex.: 89,90.'), findsOneWidget);
    expect(find.text('Informe pelo menos 1 dia.'), findsOneWidget);

    await preencherPlano(tester, 'mensal', '10', '30');
    expect(find.text('Já existe um plano com esse nome.'), findsOneWidget);
  });

  testWidgets('edita um plano tocando nele', (tester) async {
    await abrirPlanos(tester);
    await tester.tap(find.text('Mensal'));
    await tester.pumpAndSettle();

    expect(find.text('Editar plano'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '89,90'), findsOneWidget);
    await preencherPlano(tester, 'Mensal', '99,90', '30');

    expect(find.text('R\$ 99,90 · ciclo de 30 dias'), findsOneWidget);
  });

  testWidgets('desativa com confirmação e reativa', (tester) async {
    await abrirPlanos(tester);
    await tester.tap(find.byTooltip('Opções').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desativar'));
    await tester.pumpAndSettle();

    expect(find.text('Desativar "Mensal"?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Desativar'));
    await tester.pumpAndSettle();
    expect(find.text('Inativo'), findsOneWidget);

    await tester.tap(find.byTooltip('Opções').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reativar'));
    await tester.pumpAndSettle();
    expect(find.text('Inativo'), findsNothing);
  });
}
