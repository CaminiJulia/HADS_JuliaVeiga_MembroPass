import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/app.dart';
import 'package:membropass/features/auth/data/auth_repositorio_mock.dart';
import 'package:membropass/repositorios.dart';

/// Abre o app com os repositórios simulados, entra como administrador e,
/// se [secao] for informada, toca nela no painel.
Future<void> entrarComoAdmin(WidgetTester tester, {String? secao}) async {
  await tester.pumpWidget(MembroPassApp(repositorios: Repositorios.simulados()));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('botao-entrar-com-email')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('campo-email')), 'admin@membropass.dev');
  await tester.enterText(find.byKey(const Key('campo-senha')), AuthRepositorioMock.senhaPadrao);
  await tester.ensureVisible(find.byKey(const Key('botao-entrar')));
  await tester.tap(find.byKey(const Key('botao-entrar')));
  await tester.pumpAndSettle();

  expect(find.text('Clube Exemplo'), findsOneWidget);
  if (secao == null) return;
  await rolarAte(tester, find.text(secao));
  await tester.tap(find.text(secao));
  await tester.pumpAndSettle();
}

/// Rola a lista principal da tela (a primeira área rolável) até [alvo] aparecer.
Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
  await tester.scrollUntilVisible(alvo, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}
