import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/app.dart';
import 'package:membropass/features/area_membro/data/area_membro_repositorio.dart';
import 'package:membropass/features/auth/data/auth_repositorio_mock.dart';
import 'package:membropass/features/membros/domain/membro.dart';
import 'package:membropass/repositorios.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  /// Entra como membro com a carteirinha simulada por [area].
  Future<void> entrarComoMembro(WidgetTester tester, [AreaMembroRepositorioMock? area]) async {
    await tester.pumpWidget(MembroPassApp(repositorios: Repositorios.simulados(areaMembro: area)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-entrar-com-email')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo-email')), 'membro@membropass.dev');
    await tester.enterText(find.byKey(const Key('campo-senha')), AuthRepositorioMock.senhaPadrao);
    await tester.ensureVisible(find.byKey(const Key('botao-entrar')));
    await tester.tap(find.byKey(const Key('botao-entrar')));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra a carteirinha com nome, plano e o QR Code', (tester) async {
    await entrarComoMembro(tester);

    expect(find.text('Marina Membro'), findsOneWidget);
    expect(find.textContaining('Plano Mensal'), findsOneWidget);
    expect(find.text('Carteirinha em dia'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('qr-carteirinha')), 200);
    expect(find.text('Nº 38F29DBA'), findsOneWidget);
    expect(tester.widget<QrImageView>(find.byKey(const Key('qr-carteirinha'))), isNotNull);
  });

  testWidgets('renova o QR Code antes de expirar', (tester) async {
    final area = AreaMembroRepositorioMock();
    await entrarComoMembro(tester, area);
    expect(area.buscas, 1);

    // O QR simulado vale 5 minutos; o app renova 15 s antes do fim.
    await tester.pump(const Duration(minutes: 4, seconds: 50));
    await tester.pump();
    expect(area.buscas, 2);
  });

  testWidgets('sem conexão, avisa e tira o QR expirado da tela', (tester) async {
    final area = AreaMembroRepositorioMock();
    await entrarComoMembro(tester, area);
    area.semConexao = true;

    // A renovação falha 15 s antes do fim; o app avisa e espera antes de tentar de novo.
    await tester.pump(const Duration(minutes: 4, seconds: 46));
    await tester.pump();
    expect(find.textContaining('Não foi possível atualizar a carteirinha'), findsOneWidget);
    final tentativas = area.buscas;
    await tester.pump(const Duration(seconds: 5));
    expect(area.buscas, tentativas);

    // Expirado, o código some até conseguir renovar.
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('qr-expirado')), 200);
    expect(find.byKey(const Key('qr-carteirinha')), findsNothing);

    // A conexão volta: na próxima tentativa automática, o QR reaparece.
    area.semConexao = false;
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qr-carteirinha')), findsOneWidget);
  });

  testWidgets('carteirinha bloqueada não mostra QR Code', (tester) async {
    await entrarComoMembro(tester, AreaMembroRepositorioMock(status: StatusCarteirinha.bloqueada));

    expect(find.text('Carteirinha bloqueada'), findsOneWidget);
    expect(find.byKey(const Key('qr-carteirinha')), findsNothing);
    await tester.scrollUntilVisible(find.text('QR Code indisponível'), 200);
    expect(find.text('QR Code indisponível'), findsOneWidget);
  });

  testWidgets('vencida, mas não bloqueada, avisa e mantém o QR Code', (tester) async {
    await entrarComoMembro(tester, AreaMembroRepositorioMock(diasParaVencer: -3));

    expect(find.textContaining('Pagamento vencido'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('qr-carteirinha')), 200);
    expect(find.byKey(const Key('qr-carteirinha')), findsOneWidget);
  });

  testWidgets('abas de benefícios e locais', (tester) async {
    await entrarComoMembro(tester);

    await tester.tap(find.text('Benefícios'));
    await tester.pumpAndSettle();
    expect(find.text('Desconto na farmácia'), findsOneWidget);
    expect(find.text('Nenhum plano vinculado'), findsNothing);

    await tester.tap(find.text('Locais'));
    await tester.pumpAndSettle();
    expect(find.text('Sede Central'), findsOneWidget);
  });

  testWidgets('sair pede confirmação', (tester) async {
    await entrarComoMembro(tester);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sair'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('botao-entrar-com-email')), findsOneWidget);
  });
}
