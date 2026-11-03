import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/features/beneficios/domain/beneficio.dart';

import '../../ajuda.dart';

void main() {
  Future<void> abrirBeneficios(WidgetTester tester) => entrarComoAdmin(tester, secao: 'Benefícios');

  testWidgets('lista benefícios com desconto, parceiro e planos', (tester) async {
    await abrirBeneficios(tester);

    expect(find.text('Desconto na farmácia'), findsOneWidget);
    expect(find.text('1 benefício · 1 vigente'), findsOneWidget);
    expect(find.text('15%'), findsOneWidget);
    expect(find.text('Vigente'), findsOneWidget);
    expect(find.text('Farmácia Central'), findsOneWidget);
    expect(find.text('Sem prazo de validade'), findsOneWidget);
    // Etiquetas dos planos com direito.
    expect(find.text('Mensal'), findsOneWidget);
    expect(find.text('Anual'), findsOneWidget);
  });

  testWidgets('cria benefício em valor ligado a um plano', (tester) async {
    await abrirBeneficios(tester);
    await tester.tap(find.text('Novo benefício'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-nome-beneficio')), 'Cinema');
    await tester.tap(find.text('Valor (R\$)'));
    await tester.enterText(find.byKey(const Key('campo-valor-beneficio')), '20');
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Anual'));
    await tester.tap(find.widgetWithText(FilterChip, 'Anual'));
    await tester.ensureVisible(find.byKey(const Key('botao-salvar-beneficio')));
    await tester.tap(find.byKey(const Key('botao-salvar-beneficio')));
    await tester.pumpAndSettle();

    expect(find.text('Cinema'), findsOneWidget);
    expect(find.text('R\$ 20'), findsOneWidget);
    expect(find.text('2 benefícios · 2 vigentes'), findsOneWidget);
  });

  testWidgets('não aceita percentual acima de 100%', (tester) async {
    await abrirBeneficios(tester);
    await tester.tap(find.text('Novo benefício'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-nome-beneficio')), 'X');
    await tester.enterText(find.byKey(const Key('campo-valor-beneficio')), '150');
    await tester.ensureVisible(find.byKey(const Key('botao-salvar-beneficio')));
    await tester.tap(find.byKey(const Key('botao-salvar-beneficio')));
    await tester.pumpAndSettle();

    expect(find.text('O percentual vai até 100%.'), findsOneWidget);
  });

  testWidgets('exclui com confirmação', (tester) async {
    await abrirBeneficios(tester);
    await tester.tap(find.byTooltip('Opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Desconto na farmácia'), findsNothing);
    expect(find.textContaining('Nenhum benefício ainda'), findsOneWidget);
  });

  group('Beneficio', () {
    final hoje = DateTime(2026, 6, 15);
    Beneficio comVigencia(DateTime? inicio, DateTime? fim) => Beneficio(
          id: 'x',
          nome: 'X',
          tipoDesconto: TipoDesconto.percentual,
          valorDesconto: 12.5,
          planoIds: const [],
          vigInicio: inicio,
          vigFim: fim,
        );

    test('situação da vigência', () {
      expect(comVigencia(null, null).situacao(hoje), SituacaoVigencia.vigente);
      expect(comVigencia(DateTime(2026, 6, 15), DateTime(2026, 6, 15)).situacao(hoje), SituacaoVigencia.vigente);
      expect(comVigencia(DateTime(2026, 7, 1), null).situacao(hoje), SituacaoVigencia.futuro);
      expect(comVigencia(null, DateTime(2026, 6, 14)).situacao(hoje), SituacaoVigencia.encerrado);
    });

    test('descrições', () {
      final b = comVigencia(DateTime(2026, 1, 1), DateTime(2026, 12, 31));
      expect(b.valorCurto, '12,5%');
      expect(
        Beneficio(id: 'v', nome: 'V', tipoDesconto: TipoDesconto.valor, valorDesconto: 12.5, planoIds: const []).valorCurto,
        'R\$ 12,50',
      );
      expect(b.descricaoVigencia, 'Válido de 01/01/2026 a 31/12/2026');
      expect(comVigencia(null, DateTime(2026, 12, 31)).descricaoVigencia, 'Válido até 31/12/2026');
    });
  });
}
