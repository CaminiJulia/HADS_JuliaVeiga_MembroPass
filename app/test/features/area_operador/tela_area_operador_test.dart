import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/app.dart';
import 'package:membropass/features/area_operador/data/operador_repositorio.dart';
import 'package:membropass/features/area_operador/domain/checkin.dart';
import 'package:membropass/features/area_operador/presentation/leitor_qr.dart';
import 'package:membropass/features/auth/data/auth_repositorio_mock.dart';
import 'package:membropass/features/perfil/data/perfil_repositorio.dart';
import 'package:membropass/repositorios.dart';

import '../../ajuda.dart';

void main() {
  late OperadorRepositorioMock operador;
  late LeitorQrSimulado leitor;

  setUp(() {
    operador = OperadorRepositorioMock();
    leitor = LeitorQrSimulado();
  });

  Future<void> entrarComoOperador(WidgetTester tester) async {
    await tester.pumpWidget(
      MembroPassApp(
        repositorios: Repositorios.simulados(operador: operador, perfil: PerfilRepositorioMock.operador()),
        leitorQr: leitor,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-entrar-com-email')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo-email')), 'operador@membropass.dev');
    await tester.enterText(find.byKey(const Key('campo-senha')), AuthRepositorioMock.senhaPadrao);
    await tester.ensureVisible(find.byKey(const Key('botao-entrar')));
    await tester.tap(find.byKey(const Key('botao-entrar')));
    await tester.pumpAndSettle();
  }

  Future<void> escolherSede(WidgetTester tester) async {
    await tester.tap(find.text('Sede Central'));
    await tester.pumpAndSettle();
  }

  /// Lê [codigo] no local atual e espera a tela de resultado.
  Future<void> ler(WidgetTester tester, String codigo) async {
    leitor.codigo = codigo;
    await tester.tap(find.byKey(const Key('botao-ler-qr')));
    await tester.pumpAndSettle();
  }

  /// O histórico fica abaixo da área de leitura: rola até [alvo] e confere.
  Future<void> verNoHistorico(WidgetTester tester, Finder alvo) async {
    await rolarAte(tester, alvo);
    expect(alvo, findsOneWidget);
  }

  Future<void> voltarDoResultado(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
  }

  testWidgets('pede o local e mostra só unidades e eventos de hoje', (tester) async {
    await entrarComoOperador(tester);

    expect(find.text('Onde você está?'), findsOneWidget);
    expect(find.text('Sede Central'), findsOneWidget);
    expect(find.text('Clínica de Tênis'), findsOneWidget);
    expect(find.byKey(const Key('botao-ler-qr')), findsNothing);

    await escolherSede(tester);
    expect(find.byKey(const Key('botao-ler-qr')), findsOneWidget);
    await verNoHistorico(tester, find.text('Nenhuma carteirinha lida aqui hoje.'));
  });

  testWidgets('carteirinha em dia: libera com foto, nome e plano, e entra no histórico', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await ler(tester, OperadorRepositorioMock.qrMarina);

    expect(find.byKey(Key('resultado-${DesfechoCheckin.liberado.name}')), findsOneWidget);
    expect(find.text('Entrada liberada'), findsOneWidget);
    expect(find.text('Marina Membro'), findsOneWidget);
    expect(find.text('Plano Mensal'), findsOneWidget);
    expect(find.textContaining('já entrou hoje'), findsNothing);

    await voltarDoResultado(tester);
    await rolarAte(tester, find.byKey(const Key('contador-liberadas')));
    expect(find.descendant(of: find.byKey(const Key('contador-liberadas')), matching: find.text('1')), findsOneWidget);
    await verNoHistorico(tester, find.text('Marina Membro'));
    expect(find.text('Plano Mensal'), findsOneWidget);
  });

  testWidgets('carteirinha vencida, mas ativa: libera com alerta de pagamento', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await ler(tester, OperadorRepositorioMock.qrCarla);

    expect(find.byKey(Key('resultado-${DesfechoCheckin.liberadoComAlerta.name}')), findsOneWidget);
    expect(find.text('Entrada liberada'), findsOneWidget);
    expect(find.textContaining('Pagamento vencido desde'), findsOneWidget);
  });

  testWidgets('carteirinha bloqueada: recusa e mostra o motivo', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await ler(tester, OperadorRepositorioMock.qrBruno);

    expect(find.byKey(Key('resultado-${DesfechoCheckin.recusado.name}')), findsOneWidget);
    expect(find.text('Entrada recusada'), findsOneWidget);
    expect(find.text('Carteirinha bloqueada pela administração.'), findsOneWidget);
    expect(find.text('Bruno Souza'), findsOneWidget);
  });

  testWidgets('QR Code desconhecido: recusa sem dados de membro', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await ler(tester, 'https://exemplo.com');

    expect(find.text('Entrada recusada'), findsOneWidget);
    expect(find.textContaining('não reconhecido'), findsOneWidget);

    await voltarDoResultado(tester);
    await rolarAte(tester, find.byKey(const Key('contador-recusadas')));
    expect(find.descendant(of: find.byKey(const Key('contador-recusadas')), matching: find.text('1')), findsOneWidget);
    await verNoHistorico(tester, find.text('QR Code não reconhecido'));
  });

  testWidgets('a mesma carteirinha duas vezes no dia avisa a entrada anterior', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await ler(tester, OperadorRepositorioMock.qrMarina);
    await voltarDoResultado(tester);
    await ler(tester, OperadorRepositorioMock.qrMarina);

    expect(find.text('Entrada liberada'), findsOneWidget);
    expect(find.textContaining('já entrou hoje neste local'), findsOneWidget);
  });

  testWidgets('"Ler próxima" volta para a câmera; desistir volta ao painel', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await ler(tester, OperadorRepositorioMock.qrMarina);

    leitor.codigo = OperadorRepositorioMock.qrBruno;
    await tester.tap(find.byKey(const Key('botao-ler-proxima')));
    await tester.pumpAndSettle();
    expect(find.text('Entrada recusada'), findsOneWidget);

    leitor.codigo = null;
    await tester.tap(find.byKey(const Key('botao-ler-proxima')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('botao-ler-qr')), findsOneWidget);
    expect(operador.registros['e1'], hasLength(2));
  });

  testWidgets('sem conexão ao validar, avisa e continua no local', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    operador.semConexao = true;
    await ler(tester, OperadorRepositorioMock.qrMarina);

    expect(find.textContaining('Não foi possível falar com o servidor'), findsOneWidget);
    expect(find.byKey(const Key('botao-ler-qr')), findsOneWidget);
  });

  testWidgets('as leituras ficam separadas por local', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await ler(tester, OperadorRepositorioMock.qrMarina);
    await voltarDoResultado(tester);

    await tester.tap(find.byKey(const Key('botao-trocar-local')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clínica de Tênis'));
    await tester.pumpAndSettle();
    await verNoHistorico(tester, find.text('Nenhuma carteirinha lida aqui hoje.'));
  });

  /// Abre o diálogo pelo painel e digita [numero].
  Future<void> digitarNumero(WidgetTester tester, String numero) async {
    await tester.tap(find.byKey(const Key('botao-digitar-numero')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo-numero-carteirinha')), numero);
    await tester.pump();
  }

  testWidgets('pelo número digitado: libera e pede para conferir a foto', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await digitarNumero(tester, '38f29dba');
    await tester.tap(find.byKey(const Key('botao-validar-numero')));
    await tester.pumpAndSettle();

    expect(find.text('Entrada liberada'), findsOneWidget);
    expect(find.text('Marina Membro'), findsOneWidget);
    expect(find.textContaining('Validada pelo número digitado'), findsOneWidget);

    await voltarDoResultado(tester);
    await verNoHistorico(tester, find.textContaining('número digitado'));
  });

  testWidgets('o campo aceita só 0-9 e A-F, e valida com 8 caracteres', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await digitarNumero(tester, '38F2-Z');

    expect(find.text('38F2'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('botao-validar-numero'))).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('campo-numero-carteirinha')), '38F29DBA');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(const Key('botao-validar-numero'))).onPressed, isNotNull);
  });

  testWidgets('número que não existe: recusa', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await digitarNumero(tester, '00000000');
    await tester.tap(find.byKey(const Key('botao-validar-numero')));
    await tester.pumpAndSettle();

    expect(find.text('Entrada recusada'), findsOneWidget);
    expect(find.textContaining('com este número'), findsOneWidget);

    await voltarDoResultado(tester);
    await verNoHistorico(tester, find.text('Número não reconhecido'));
  });

  testWidgets('número de carteirinha bloqueada: recusa como pelo QR', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await digitarNumero(tester, '7C01B4F2');
    await tester.tap(find.byKey(const Key('botao-validar-numero')));
    await tester.pumpAndSettle();

    expect(find.text('Carteirinha bloqueada pela administração.'), findsOneWidget);
  });

  testWidgets('cancelar o número não registra nada', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await digitarNumero(tester, '38F29DBA');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('botao-ler-qr')), findsOneWidget);
    expect(operador.registros['e1'], isNull);
  });

  testWidgets('o filtro mostra só as recusadas', (tester) async {
    await entrarComoOperador(tester);
    await escolherSede(tester);
    await ler(tester, OperadorRepositorioMock.qrMarina);
    await voltarDoResultado(tester);
    await ler(tester, 'qualquer-coisa');
    await voltarDoResultado(tester);

    await rolarAte(tester, find.byKey(const Key('filtro-recusadas')));
    await tester.tap(find.byKey(const Key('filtro-recusadas')));
    await tester.pumpAndSettle();
    await verNoHistorico(tester, find.text('QR Code não reconhecido'));
    expect(find.text('Marina Membro'), findsNothing);
  });

  testWidgets('cabe num celular estreito sem estourar o layout', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3; // 360 x 780
    addTearDown(tester.view.reset);

    await entrarComoOperador(tester);
    await escolherSede(tester);
    await ler(tester, OperadorRepositorioMock.qrCarla);
    await voltarDoResultado(tester);
    await verNoHistorico(tester, find.text('Carla Dias'));
  });

  testWidgets('o avatar do cabeçalho abre o perfil do operador, sem cargo', (tester) async {
    await entrarComoOperador(tester);
    await tester.tap(find.byTooltip('Meu perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('Operador'), findsOneWidget);
    expect(find.text('Administrador'), findsNothing);
    expect(find.byKey(const Key('campo-cargo-perfil')), findsNothing);
    await rolarAte(tester, find.text('operador@membropass.dev'));
    expect(find.text('Alterar senha'), findsOneWidget);
  });

  testWidgets('o nome salvo no perfil aparece na saudação do operador', (tester) async {
    await entrarComoOperador(tester);
    expect(find.textContaining('Olá, Otávio'), findsOneWidget);
    await tester.tap(find.byTooltip('Meu perfil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-nome-perfil')), 'Rafael Operador');
    await tester.pump();
    await tester.tap(find.byKey(const Key('botao-salvar-perfil')));
    await tester.pumpAndSettle();
    expect(find.text('Perfil atualizado.'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('Olá, Rafael'), findsOneWidget);
    expect(find.text('RO'), findsOneWidget);
  });
}
