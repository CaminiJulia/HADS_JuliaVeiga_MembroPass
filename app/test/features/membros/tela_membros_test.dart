import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/features/membros/data/membros_repositorio_mock.dart';
import 'package:membropass/features/membros/domain/membro.dart';

import '../../ajuda.dart';

void main() {
  Future<void> abrirMembros(WidgetTester tester) => entrarComoAdmin(tester, secao: 'Membros');

  testWidgets('lista membros com a situação de cada um', (tester) async {
    await abrirMembros(tester);

    expect(find.text('Marina Membro'), findsOneWidget);
    expect(find.text('3 membros'), findsOneWidget);
    // Os rótulos aparecem no chip de filtro e no selo do membro.
    expect(find.text('Em dia'), findsNWidgets(2));
    expect(find.text('Vence em breve'), findsNWidgets(2));
    expect(find.text('Vencido'), findsOneWidget);
  });

  testWidgets('ordena por vencimento, com o mais urgente primeiro', (tester) async {
    await abrirMembros(tester);
    await tester.tap(find.byTooltip('Ordenar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vencimento (mais urgente)'));
    await tester.pumpAndSettle();

    final carla = tester.getTopLeft(find.text('Carla Dias')).dy;
    final bruno = tester.getTopLeft(find.text('Bruno Souza')).dy;
    final marina = tester.getTopLeft(find.text('Marina Membro')).dy;
    expect(carla < bruno && bruno < marina, isTrue);
  });

  testWidgets('busca e filtra por situação', (tester) async {
    await abrirMembros(tester);

    await tester.enterText(find.byKey(const Key('campo-busca-membro')), 'bru');
    await tester.pump();
    expect(find.text('Bruno Souza'), findsOneWidget);
    expect(find.text('Marina Membro'), findsNothing);

    await tester.enterText(find.byKey(const Key('campo-busca-membro')), '');
    // Os filtros ficam numa faixa horizontal: arrasta até o chip aparecer.
    await tester.dragUntilVisible(
      find.byKey(const Key('filtro-vencidos')),
      find.byType(ListView).first,
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filtro-vencidos')));
    await tester.pump();
    expect(find.text('Carla Dias'), findsOneWidget);
    expect(find.text('Bruno Souza'), findsNothing);
    expect(find.text('1 de 3 membros'), findsOneWidget);
  });

  testWidgets('cadastra membro e mostra a senha provisória', (tester) async {
    await abrirMembros(tester);
    await tester.tap(find.text('Novo membro'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-nome-membro')), 'Eva Nunes');
    await tester.enterText(find.byKey(const Key('campo-email-membro')), 'Eva@Exemplo.com');
    await tester.tap(find.byKey(const Key('campo-plano-membro')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anual').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-salvar-membro')));
    await tester.pumpAndSettle();

    expect(find.text('Cadastro de Eva Nunes criado'), findsOneWidget);
    expect(find.text(MembrosRepositorioMock.senhaProvisoria), findsOneWidget);
    await tester.tap(find.text('Pronto'));
    await tester.pumpAndSettle();
    expect(find.text('Eva Nunes'), findsOneWidget);
  });

  testWidgets('não deixa repetir e-mail', (tester) async {
    await abrirMembros(tester);
    await tester.tap(find.text('Novo membro'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-nome-membro')), 'Outra');
    await tester.enterText(find.byKey(const Key('campo-email-membro')), 'bruno@exemplo.com');
    await tester.tap(find.byKey(const Key('campo-plano-membro')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mensal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-salvar-membro')));
    await tester.pumpAndSettle();

    expect(find.text('Este e-mail já está em uso por outra conta.'), findsOneWidget);
  });

  testWidgets('desativa pelo detalhe, com motivo opcional', (tester) async {
    await abrirMembros(tester);
    await tester.tap(find.text('Marina Membro'));
    await tester.pumpAndSettle();

    expect(find.text('membro@membropass.dev'), findsOneWidget);
    await rolarAte(tester, find.text('Desativar membro'));
    await tester.tap(find.text('Desativar membro'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Desativar'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastro de Marina Membro desativado.'), findsOneWidget);
    expect(find.text('Reativar membro'), findsOneWidget);
    expect(find.text('Confirmar pagamento'), findsNothing);
  });

  group('Membro.situacao', () {
    final hoje = DateTime(2026, 6, 15);
    Membro membro({int venceEm = 30, bool ativo = true, StatusCarteirinha status = StatusCarteirinha.ativa}) => Membro(
      id: 'x',
      nome: 'Ana Maria Souza',
      email: 'a@b.com',
      planoId: 'p',
      planoNome: 'Mensal',
      planoDuracaoDias: 30,
      dataAdesao: hoje,
      ativo: ativo,
      carteirinha: Carteirinha(
        status: status,
        dataVencimento: hoje.add(Duration(days: venceEm)),
        qrVersao: 1,
      ),
    );

    test('em dia, vence em breve e vencido pelo vencimento', () {
      expect(membro(venceEm: 8).situacao(hoje), SituacaoMembro.emDia);
      expect(membro(venceEm: 7).situacao(hoje), SituacaoMembro.venceEmBreve);
      expect(membro(venceEm: 0).situacao(hoje), SituacaoMembro.venceEmBreve);
      expect(membro(venceEm: -1).situacao(hoje), SituacaoMembro.vencido);
    });

    test('desativado e bloqueado têm prioridade sobre o vencimento', () {
      expect(membro(ativo: false, venceEm: -5).situacao(hoje), SituacaoMembro.desativado);
      expect(membro(status: StatusCarteirinha.bloqueada).situacao(hoje), SituacaoMembro.bloqueado);
    });

    test('textos de vencimento e iniciais', () {
      expect(membro(venceEm: 0).descricaoVencimento(hoje), 'Vence hoje (15/06/2026)');
      expect(membro(venceEm: -10).descricaoVencimento(hoje), 'Venceu há 10 dias (05/06/2026)');
      expect(membro().iniciais, 'AS');
    });
  });
}
