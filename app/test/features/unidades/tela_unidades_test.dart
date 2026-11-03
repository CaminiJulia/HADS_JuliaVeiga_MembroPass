import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/features/unidades/domain/unidade_evento.dart';

import '../../ajuda.dart';

void main() {
  Future<void> abrirUnidades(WidgetTester tester) => entrarComoAdmin(tester, secao: 'Unidades e eventos');

  testWidgets('lista unidades com endereço e planos aceitos', (tester) async {
    await abrirUnidades(tester);

    expect(find.text('Sede Central'), findsOneWidget);
    expect(find.text('Rua das Flores, 100'), findsOneWidget);
    expect(find.text('Aceita: Mensal, Anual'), findsOneWidget);
  });

  testWidgets('cadastra unidade aceitando todos os planos ativos', (tester) async {
    await abrirUnidades(tester);
    await tester.tap(find.text('Novo local'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-nome-local')), 'Filial Norte');
    await tester.tap(find.byKey(const Key('botao-salvar-local')));
    await tester.pumpAndSettle();

    expect(find.text('Filial Norte'), findsOneWidget);
    expect(find.text('Aceita: Mensal, Anual'), findsNWidgets(2));
  });

  testWidgets('evento exige período', (tester) async {
    await abrirUnidades(tester);
    await tester.tap(find.text('Novo local'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Evento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo-nome-local')), 'Torneio');
    await tester.ensureVisible(find.byKey(const Key('botao-salvar-local')));
    await tester.tap(find.byKey(const Key('botao-salvar-local')));
    await tester.pumpAndSettle();

    expect(find.text('Informe o início e o fim do evento.'), findsOneWidget);
  });

  test('período e encerramento do evento', () {
    final evento = UnidadeEvento(
      id: 'e',
      nome: 'Feira',
      tipo: TipoLocal.evento,
      planoIds: const [],
      dataInicio: DateTime(2026, 12, 1),
      dataFim: DateTime(2026, 12, 3),
    );
    expect(evento.periodo, '01/12/2026 a 03/12/2026');
    expect(evento.encerrado(DateTime(2026, 12, 3)), isFalse);
    expect(evento.encerrado(DateTime(2026, 12, 4)), isTrue);
  });
}
