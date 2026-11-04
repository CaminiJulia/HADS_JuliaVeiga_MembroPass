import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/core/suporte.dart';
import 'package:membropass/core/tema/contraste.dart';

import '../../ajuda.dart';

void main() {
  Future<void> abrirIdentidade(WidgetTester tester) => entrarComoAdmin(tester, secao: 'Identidade visual');

  testWidgets('mostra a prévia com a cor padrão e contraste legível', (tester) async {
    await abrirIdentidade(tester);

    expect(find.text('PRÉVIA DA CARTEIRINHA'), findsOneWidget);
    expect(find.text('Clube Exemplo'), findsOneWidget);
    await rolarAte(tester, find.byKey(const Key('texto-contraste')));
    expect(find.textContaining('Boa leitura'), findsOneWidget);
  });

  testWidgets('cor clara demais bloqueia o salvamento', (tester) async {
    await abrirIdentidade(tester);

    await rolarAte(tester, find.byKey(const Key('campo-cor-hex')));
    await tester.enterText(find.byKey(const Key('campo-cor-hex')), '#FFD54F');
    await tester.pump();

    expect(find.textContaining('Cor clara demais'), findsOneWidget);
    final botao = tester.widget<FilledButton>(find.byKey(const Key('botao-salvar-identidade')));
    expect(botao.onPressed, isNull);
  });

  testWidgets('salva uma cor sugerida', (tester) async {
    await abrirIdentidade(tester);

    await rolarAte(tester, find.bySemanticsLabel('Cor #0B6E4F'));
    await tester.tap(find.bySemanticsLabel('Cor #0B6E4F'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('botao-salvar-identidade')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Identidade visual salva'), findsOneWidget);
  });

  testWidgets('troca o modelo e o fundo e salva', (tester) async {
    await abrirIdentidade(tester);

    await rolarAte(tester, find.bySemanticsLabel('Modelo Moderno'));
    await tester.tap(find.bySemanticsLabel('Modelo Moderno'));
    await tester.pump();
    await rolarAte(tester, find.text('Padrão'));
    await tester.tap(find.text('Padrão'));
    await tester.pump();
    // Sem degradê, a escolha da segunda cor some.
    expect(find.text('Segunda cor do degradê'), findsNothing);

    await tester.tap(find.byKey(const Key('botao-salvar-identidade')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Identidade visual salva'), findsOneWidget);
  });

  testWidgets('no degradê, escolhe a segunda cor', (tester) async {
    await abrirIdentidade(tester);

    await rolarAte(tester, find.bySemanticsLabel('Segunda cor #0B6E4F'));
    await tester.tap(find.bySemanticsLabel('Segunda cor #0B6E4F'));
    await tester.pump();
    // A amostra escolhida ganha o ✓.
    expect(
      find.descendant(of: find.bySemanticsLabel('Segunda cor #0B6E4F'), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
  });

  testWidgets('a rodinha abre a roda de cores e só aceita cores legíveis', (tester) async {
    await abrirIdentidade(tester);

    // Cor digitada fora das sugestões: a rodinha fica marcada com ela.
    await rolarAte(tester, find.byKey(const Key('campo-cor-hex')));
    await tester.enterText(find.byKey(const Key('campo-cor-hex')), '#123456');
    await tester.pump();
    await rolarAte(tester, find.bySemanticsLabel('Cor personalizada'));
    await tester.tap(find.bySemanticsLabel('Cor personalizada'));
    await tester.pumpAndSettle();

    expect(find.text('Cor principal'), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('#123456')), findsOneWidget);
    expect(find.textContaining('Boa leitura'), findsWidgets);
    await tester.tap(find.byKey(const Key('botao-usar-cor')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('botao-usar-cor')), findsNothing);

    // Cor clara: a roda avisa e não deixa usar.
    await tester.enterText(find.byKey(const Key('campo-cor-hex')), '#FFD54F');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Cor personalizada'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Clara demais para o texto branco'), findsOneWidget);
    final usar = tester.widget<FilledButton>(find.byKey(const Key('botao-usar-cor')));
    expect(usar.onPressed, isNull);
  });

  testWidgets('painel mostra o contato do suporte', (tester) async {
    await entrarComoAdmin(tester);
    await rolarAte(tester, find.text(Suporte.email));

    expect(find.text('Precisa de ajuda?'), findsOneWidget);
    expect(find.text(Suporte.whatsapp), findsOneWidget);
  });

  group('Contraste', () {
    test('valores de referência da WCAG', () {
      expect(Contraste.comBranco(const Color(0xFF000000)), closeTo(21, 0.01));
      expect(Contraste.comBranco(const Color(0xFF767676)), closeTo(4.54, 0.01));
      expect(Contraste.legivelComBranco(const Color(0xFFFFD54F)), isFalse);
    });

    test('todas as cores sugeridas são legíveis', () {
      for (final hex in [
        '#2B2FB8',
        '#14163A',
        '#0B6E4F',
        '#1565C0',
        '#6A1B9A',
        '#AD1457',
        '#C62828',
        '#B34700',
        '#37474F',
      ]) {
        expect(Contraste.legivelComBranco(Contraste.lerHex(hex)!), isTrue, reason: hex);
      }
    });

    test('conversão de hexadecimal', () {
      expect(Contraste.paraHex(Contraste.lerHex('2b2fb8')!), '#2B2FB8');
      expect(Contraste.lerHex('#XYZ123'), isNull);
    });
  });
}
