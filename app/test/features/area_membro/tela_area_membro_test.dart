import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/app.dart';
import 'package:membropass/features/area_membro/data/area_membro_repositorio.dart';
import 'package:membropass/features/auth/data/auth_repositorio_mock.dart';
import 'package:membropass/features/membros/domain/membro.dart';
import 'package:membropass/repositorios.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../ajuda.dart';

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
    // Em dia, não há aviso: a carteirinha ocupa a tela.
    expect(find.byKey(const Key('aviso-situacao-carteirinha')), findsNothing);
    expect(find.text('Nº 38F29DBA'), findsOneWidget);
    expect(tester.widget<QrImageView>(find.byKey(const Key('qr-carteirinha'))), isNotNull);
  });

  testWidgets('o QR Code é fixo: não é buscado de novo com o tempo', (tester) async {
    final area = AreaMembroRepositorioMock();
    await entrarComoMembro(tester, area);

    await tester.pump(const Duration(minutes: 10));
    expect(area.buscas, 1);
    expect(find.byKey(const Key('qr-carteirinha')), findsOneWidget);
    expect(find.text('Gerar novo código'), findsNothing);
  });

  testWidgets('sem conexão ao atualizar, avisa e mantém a carteirinha', (tester) async {
    final area = AreaMembroRepositorioMock();
    await entrarComoMembro(tester, area);
    area.semConexao = true;

    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível atualizar a carteirinha'), findsOneWidget);
    expect(find.byKey(const Key('qr-carteirinha')), findsOneWidget);
  });

  testWidgets('tocar no QR Code amplia, e tocar de novo fecha', (tester) async {
    await entrarComoMembro(tester);

    await tester.tap(find.byKey(const Key('botao-ampliar-qr')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qr-ampliado')), findsOneWidget);
    expect(find.text('Toque para fechar'), findsOneWidget);
    expect(find.byType(QrImageView), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('qr-ampliado')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qr-ampliado')), findsNothing);
  });

  testWidgets('carteirinha bloqueada não mostra QR Code', (tester) async {
    await entrarComoMembro(tester, AreaMembroRepositorioMock(status: StatusCarteirinha.bloqueada));

    expect(find.text('Carteirinha bloqueada'), findsOneWidget);
    expect(find.byKey(const Key('qr-carteirinha')), findsNothing);
    expect(find.byKey(const Key('aviso-qr')), findsOneWidget);
  });

  testWidgets('vencida, mas não bloqueada, avisa e mantém o QR Code', (tester) async {
    await entrarComoMembro(tester, AreaMembroRepositorioMock(diasParaVencer: -3));

    expect(find.textContaining('Pagamento vencido'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('qr-carteirinha')), 200);
    expect(find.byKey(const Key('qr-carteirinha')), findsOneWidget);
  });

  testWidgets('a foto do membro aparece na carteirinha e pode ser removida', (tester) async {
    final area = AreaMembroRepositorioMock()..foto = Uint8List.fromList(_pngTransparente);
    await entrarComoMembro(tester, area);

    expect(find.bySemanticsLabel('Trocar foto'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Trocar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover foto'));
    await tester.pumpAndSettle();

    expect(area.foto, isNull);
    expect(find.text('Foto removida.'), findsOneWidget);
    expect(find.bySemanticsLabel('Adicionar foto'), findsOneWidget);
    expect(find.text('Toque na foto para adicionar a sua.'), findsOneWidget);
  });

  group('primeiro acesso', () {
    Future<void> preencher(WidgetTester tester) async {
      Future<void> digitar(String chave, String texto) async {
        await rolarAte(tester, find.byKey(Key(chave)));
        await tester.enterText(find.byKey(Key(chave)), texto);
      }

      await digitar('campo-nome-cadastro', 'Marina Souza Membro');
      await digitar('campo-celular-cadastro', '54999990001');
      await digitar('campo-nascimento-cadastro', '15041995');
      await digitar('campo-cep-cadastro', '99300000');
      await digitar('campo-rua-cadastro', 'Rua das Flores');
      await digitar('campo-numero-cadastro', '100');
      await digitar('campo-bairro-cadastro', 'Centro');
      await digitar('campo-cidade-cadastro', 'Soledade');
      await rolarAte(tester, find.byKey(const Key('campo-uf-cadastro')));
      await tester.tap(find.byKey(const Key('campo-uf-cadastro')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('RS'), 100, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('RS'));
      await tester.pumpAndSettle();
    }

    testWidgets('pede o cadastro antes da carteirinha, com o aviso de veracidade', (tester) async {
      await entrarComoMembro(tester, AreaMembroRepositorioMock(cadastroPendente: true));

      expect(find.text('Complete seu cadastro'), findsOneWidget);
      expect(find.byKey(const Key('aviso-veracidade')), findsOneWidget);
      expect(find.textContaining('risco de ser expulso'), findsOneWidget);
      expect(find.byKey(const Key('qr-carteirinha')), findsNothing);
      // O nome já vem preenchido, para o membro conferir.
      await rolarAte(tester, find.byKey(const Key('campo-nome-cadastro')));
      expect(find.widgetWithText(TextFormField, 'Marina Membro'), findsOneWidget);
      // Sem marcar a declaração, não dá para concluir.
      final botao = tester.widget<FilledButton>(find.byKey(const Key('botao-concluir-cadastro')));
      expect(botao.onPressed, isNull);
    });

    testWidgets('por enquanto é opcional: "Preencher depois" abre a carteirinha', (tester) async {
      final area = AreaMembroRepositorioMock(cadastroPendente: true);
      await entrarComoMembro(tester, area);

      await tester.tap(find.byKey(const Key('botao-preencher-depois')));
      await tester.pumpAndSettle();

      expect(find.text('Complete seu cadastro'), findsNothing);
      expect(find.byKey(const Key('qr-carteirinha')), findsOneWidget);
      expect(area.cadastroEnviado, isNull);
    });

    testWidgets('máscaras e validação dos campos', (tester) async {
      await entrarComoMembro(tester, AreaMembroRepositorioMock(cadastroPendente: true));
      await rolarAte(tester, find.byKey(const Key('campo-celular-cadastro')));
      await tester.enterText(find.byKey(const Key('campo-celular-cadastro')), '54999990001');
      await rolarAte(tester, find.byKey(const Key('campo-nascimento-cadastro')));
      await tester.enterText(find.byKey(const Key('campo-nascimento-cadastro')), '31022000');
      await tester.pump();
      expect(find.text('(54) 99999-0001'), findsOneWidget);
      expect(find.text('31/02/2000'), findsOneWidget);

      await rolarAte(tester, find.byKey(const Key('declaracao-veracidade')));
      await tester.tap(find.byKey(const Key('declaracao-veracidade')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('botao-concluir-cadastro')));
      await tester.pumpAndSettle();
      // O erro fica acima: rola para cima até ele.
      await tester.scrollUntilVisible(
        find.text('Informe uma data válida (DD/MM/AAAA).'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Informe uma data válida (DD/MM/AAAA).'), findsOneWidget);
    });

    testWidgets('sem foto, não conclui', (tester) async {
      final area = AreaMembroRepositorioMock(cadastroPendente: true);
      await entrarComoMembro(tester, area);
      await preencher(tester);
      await rolarAte(tester, find.byKey(const Key('declaracao-veracidade')));
      await tester.tap(find.byKey(const Key('declaracao-veracidade')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('botao-concluir-cadastro')));
      await tester.pumpAndSettle();

      expect(area.cadastroEnviado, isNull);
      expect(find.text('Escolha uma foto para a carteirinha.'), findsWidgets);
    });

    testWidgets('preenchido e declarado, mostra a carteirinha', (tester) async {
      final area = AreaMembroRepositorioMock(cadastroPendente: true)..foto = Uint8List.fromList(_pngTransparente);
      await entrarComoMembro(tester, area);
      await preencher(tester);
      await rolarAte(tester, find.byKey(const Key('declaracao-veracidade')));
      await tester.tap(find.byKey(const Key('declaracao-veracidade')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('botao-concluir-cadastro')));
      await tester.pumpAndSettle();

      final enviado = area.cadastroEnviado!;
      expect(enviado.nome, 'Marina Souza Membro');
      expect(enviado.telefone, '(54) 99999-0001');
      expect(enviado.dataNascimento, DateTime(1995, 4, 15));
      expect(enviado.endereco.cep, '99300-000');
      expect(enviado.endereco.uf, 'RS');
      expect(enviado.endereco.complemento, isNull);

      expect(find.text('Complete seu cadastro'), findsNothing);
      expect(find.text('Marina Souza Membro'), findsOneWidget);
      expect(find.byKey(const Key('qr-carteirinha')), findsOneWidget);
    });
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

/// PNG 1x1 transparente, para simular uma foto.
const _pngTransparente = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
  0x42, 0x60, 0x82,
];
