import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/core/formatacao/datas.dart';
import 'package:membropass/features/unidades/domain/unidade_evento.dart';

import '../../ajuda.dart';

void main() {
  Future<void> abrirUnidades(WidgetTester tester) => entrarComoAdmin(tester, secao: 'Unidades e eventos');

  testWidgets('lista unidades com endereço e planos aceitos', (tester) async {
    await abrirUnidades(tester);

    expect(find.text('Sede Central'), findsOneWidget);
    expect(find.text('Rua das Flores, 100'), findsOneWidget);
    expect(find.text('UNIDADES · 1'), findsOneWidget);
    // Etiquetas dos planos aceitos.
    expect(find.text('Mensal'), findsOneWidget);
    expect(find.text('Anual'), findsOneWidget);
  });

  testWidgets('cadastra unidade aceitando todos os planos ativos', (tester) async {
    await abrirUnidades(tester);
    await tester.tap(find.text('Novo local'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-nome-local')), 'Filial Norte');
    expect(find.text('Foto do local'), findsOneWidget);
    await rolarAte(tester, find.byKey(const Key('botao-salvar-local')));
    await tester.tap(find.byKey(const Key('botao-salvar-local')));
    await tester.pumpAndSettle();

    expect(find.text('Filial Norte'), findsOneWidget);
    expect(find.text('UNIDADES · 2'), findsOneWidget);
    expect(find.text('Mensal'), findsNWidgets(2));
  });

  testWidgets('evento exige período', (tester) async {
    await abrirUnidades(tester);
    await tester.tap(find.text('Novo local'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Evento'));
    await tester.pumpAndSettle();
    expect(find.text('Banner do evento'), findsOneWidget);
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
    expect(evento.encerrado(DateTime(2026, 12, 3)), isFalse);
    expect(evento.encerrado(DateTime(2026, 12, 4)), isTrue);
    expect(evento.situacao(DateTime(2026, 11, 21)), SituacaoEvento.futuro);
    expect(evento.diasParaComecar(DateTime(2026, 11, 21)), 10);
    expect(evento.situacao(DateTime(2026, 12, 2)), SituacaoEvento.acontecendo);
    expect(evento.situacao(DateTime(2026, 12, 4)), SituacaoEvento.encerrado);
  });

  test('período por extenso', () {
    expect(Datas.periodoPorExtenso(DateTime(2026, 11, 23), DateTime(2026, 11, 25)), '23 a 25 de novembro de 2026');
    expect(Datas.periodoPorExtenso(DateTime(2026, 11, 30), DateTime(2026, 12, 2)), '30 de novembro a 2 de dezembro de 2026');
    expect(Datas.periodoPorExtenso(DateTime(2026, 3, 5), DateTime(2026, 3, 5)), '5 de março de 2026');
    expect(Datas.mesAbreviado(3), 'MAR');
  });
}
