import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/core/formatacao/datas.dart';
import 'package:membropass/features/membros/domain/membro.dart';

import '../../ajuda.dart';

void main() {
  Future<void> abrirMembro(WidgetTester tester, String nome) async {
    await entrarComoAdmin(tester, secao: 'Membros');
    await tester.tap(find.text(nome));
    await tester.pumpAndSettle();
  }

  testWidgets('"Ciclos e bloqueios" mostra só quem precisa de atenção', (tester) async {
    await entrarComoAdmin(tester, secao: 'Ciclos e bloqueios');

    expect(find.text('Ciclos e bloqueios'), findsOneWidget);
    expect(find.text('Bruno Souza'), findsOneWidget);
    expect(find.text('Carla Dias'), findsOneWidget);
    expect(find.text('Marina Membro'), findsNothing);
  });

  testWidgets('confirma pagamento de membro vencido, com prévia do vencimento', (tester) async {
    await abrirMembro(tester, 'Carla Dias');
    expect(find.text('Vencido'), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao-confirmar-pagamento')));
    await tester.pumpAndSettle();
    final novo = Datas.formatar(Datas.hoje().add(const Duration(days: 365)));
    expect(find.text(novo), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao-confirmar-dialogo-pagamento')));
    await tester.pumpAndSettle();

    expect(find.text('Em dia'), findsOneWidget);
    expect(find.text('Versão do QR Code: 2'), findsOneWidget);
    await rolarAte(tester, find.text('Pagamento confirmado'));
    expect(find.text('Pagamento confirmado'), findsOneWidget);
  });

  testWidgets('bloqueio exige motivo e aparece no histórico', (tester) async {
    await abrirMembro(tester, 'Marina Membro');
    await tester.tap(find.text('Bloquear carteirinha'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Bloquear'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o motivo.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo-justificativa')), 'Pagamento estornado');
    await tester.tap(find.widgetWithText(FilledButton, 'Bloquear'));
    await tester.pumpAndSettle();

    expect(find.text('Bloqueado'), findsOneWidget);
    expect(find.text('Carteirinha bloqueada'), findsWidgets);
    await rolarAte(tester, find.text('Motivo: Pagamento estornado'));
    expect(find.text('Motivo: Pagamento estornado'), findsOneWidget);

    await rolarAte(tester, find.text('Desbloquear carteirinha'));
    await tester.tap(find.text('Desbloquear carteirinha'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear'));
    await tester.pumpAndSettle();
    expect(find.text('Carteirinha desbloqueada.'), findsOneWidget);
  });

  testWidgets('ações aparecem no histórico de ações da organização', (tester) async {
    await abrirMembro(tester, 'Bruno Souza');
    await tester.tap(find.byKey(const Key('botao-confirmar-pagamento')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-confirmar-dialogo-pagamento')));
    await tester.pumpAndSettle();

    // Volta ao painel: fecha o detalhe e a lista de membros.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await rolarAte(tester, find.text('Histórico de ações'));
    await tester.tap(find.text('Histórico de ações'));
    await tester.pumpAndSettle();

    expect(find.text('Pagamento confirmado'), findsOneWidget);
    expect(find.text('Pagamento de Bruno Souza confirmado.'), findsOneWidget);
  });

  group('Membro.novoVencimento', () {
    Membro venceEm(DateTime vencimento) => Membro(
      id: 'x',
      nome: 'X',
      email: 'x@x.com',
      planoId: 'p',
      planoNome: 'Mensal',
      planoDuracaoDias: 30,
      dataAdesao: DateTime(2026, 1, 1),
      ativo: true,
      carteirinha: Carteirinha(status: StatusCarteirinha.ativa, dataVencimento: vencimento, qrVersao: 1),
    );

    test('pagamento adiantado soma a partir do vencimento atual', () {
      expect(venceEm(DateTime(2026, 6, 20)).novoVencimento(DateTime(2026, 6, 10)), DateTime(2026, 7, 20));
    });

    test('pagamento atrasado soma a partir da data do pagamento', () {
      expect(venceEm(DateTime(2026, 6, 1)).novoVencimento(DateTime(2026, 6, 10)), DateTime(2026, 7, 10));
    });
  });
}
