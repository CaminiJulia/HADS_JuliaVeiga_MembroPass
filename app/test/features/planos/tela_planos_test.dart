import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:membropass/core/tema/contraste.dart';
import 'package:membropass/features/planos/presentation/cor_plano.dart';

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
    expect(find.text('2 planos ativos'), findsOneWidget);
    expect(find.text('R\$ 89,90'), findsOneWidget);
    expect(find.text('/ 30 dias'), findsOneWidget);
    expect(find.text('R\$ 899,00'), findsOneWidget);
    expect(find.text('/ 365 dias'), findsOneWidget);
  });

  testWidgets('mostra equivalente mensal e quantos membros e benefícios cada plano tem', (tester) async {
    await abrirPlanos(tester);

    // Anual: 899 × 30 / 365 ≈ 73,89 por mês. O mensal não mostra equivalente.
    expect(find.text('≈ R\$ 73,89/mês'), findsOneWidget);
    expect(find.textContaining('/mês'), findsOneWidget);
    expect(find.text('2 membros'), findsOneWidget);
    expect(find.text('1 membro'), findsOneWidget);
    expect(find.text('1 benefício'), findsNWidgets(2));
  });

  testWidgets('cria um plano novo', (tester) async {
    await abrirPlanos(tester);
    await tester.tap(find.text('Novo plano'));
    await tester.pumpAndSettle();

    await preencherPlano(tester, 'Semestral', '1.479,9', '180');

    expect(find.text('Semestral'), findsOneWidget);
    expect(find.text('R\$ 1.479,90'), findsOneWidget);
    expect(find.text('/ 180 dias'), findsOneWidget);
  });

  testWidgets('prévia acompanha a digitação e atalho preenche duração e nome', (tester) async {
    await abrirPlanos(tester);
    await tester.tap(find.text('Novo plano'));
    await tester.pumpAndSettle();

    expect(find.text('Seu plano'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atalho-90')));
    await tester.enterText(find.byKey(const Key('campo-valor-plano')), '239,90');
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Trimestral'), findsOneWidget);
    expect(find.text('R\$ 239,90'), findsOneWidget);
    expect(find.text('/ 90 dias'), findsOneWidget);
    expect(find.text('≈ R\$ 79,97 por mês'), findsOneWidget);
  });

  testWidgets('salva a cor escolhida e mostra no cartão do plano', (tester) async {
    await abrirPlanos(tester);
    await tester.tap(find.text('Novo plano'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-nome-plano')), 'Família');
    await tester.enterText(find.byKey(const Key('campo-valor-plano')), '149,90');
    await tester.enterText(find.byKey(const Key('campo-duracao-plano')), '30');
    await rolarAte(tester, find.bySemanticsLabel('Cor #2BB5A0'));
    await tester.tap(find.bySemanticsLabel('Cor #2BB5A0'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('botao-salvar-plano')));
    await tester.pumpAndSettle();

    final cartao = find.ancestor(of: find.text('Família'), matching: find.byType(Row)).first;
    final icone = tester.widget<Icon>(find.descendant(of: cartao, matching: find.byIcon(Icons.workspace_premium_outlined)));
    expect(icone.color, const Color(0xFF2BB5A0));
  });

  testWidgets('bolinha de arco-íris abre a roda de cores', (tester) async {
    await abrirPlanos(tester);
    await tester.tap(find.text('Novo plano'));
    await tester.pumpAndSettle();

    await rolarAte(tester, find.bySemanticsLabel('Cor personalizada'));
    await tester.tap(find.bySemanticsLabel('Cor personalizada'));
    await tester.pumpAndSettle();

    expect(find.text('Cor personalizada'), findsWidgets);
    expect(find.byKey(const Key('botao-usar-cor')), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('botao-usar-cor')), findsNothing);
  });

  group('cores de plano', () {
    test('cores escuras demais para o fundo são recusadas; as sugeridas passam', () {
      expect(corEscuraDemais(const Color(0xFF101030)), isTrue);
      for (final hex in paletaPlanos) {
        expect(corEscuraDemais(corDoPlano(hex)), isFalse, reason: hex);
      }
    });

    test('a prévia escurece cores claras até o texto branco ficar legível', () {
      for (final hex in ['#FFFF00', '#FFFFFF', '#A0FFA0', ...paletaPlanos]) {
        expect(Contraste.legivelComBranco(degradeDoPlano(hex).first), isTrue, reason: hex);
      }
    });
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

    expect(find.text('R\$ 99,90'), findsOneWidget);
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
