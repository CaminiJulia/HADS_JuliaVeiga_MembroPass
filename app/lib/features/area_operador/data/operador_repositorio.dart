import '../../../core/api/cliente_api.dart';
import '../../../core/formatacao/datas.dart';
import '../../unidades/domain/unidade_evento.dart';
import '../domain/checkin.dart';

class OperadorRepositorioApi implements OperadorRepositorio {
  OperadorRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<List<UnidadeEvento>> locais() async => [
    for (final u in await _api.get('/operador/locais') as List) UnidadeEvento.deJson(u as Map<String, dynamic>),
  ];

  @override
  Future<ResultadoCheckin> registrar({required String localId, required IdentificacaoCarteirinha carteirinha}) async =>
      ResultadoCheckin.deJson(
        await _api.post('/operador/checkins', {
              'unidadeEventoId': localId,
              ...switch (carteirinha) {
                PorQr(:final codigo) => {'codigo': codigo},
                PorNumero(:final numero) => {'numero': numero},
              },
            })
            as Map<String, dynamic>,
      );

  @override
  Future<List<RegistroCheckin>> checkinsDeHoje(String localId) async => [
    for (final r in await _api.get('/operador/locais/$localId/checkins') as List)
      RegistroCheckin.deJson(r as Map<String, dynamic>),
  ];
}

/// Check-in em memória, para os testes rodarem sem a API e sem câmera.
/// Códigos conhecidos: [qrMarina] (em dia), [qrCarla] (vencida) e
/// [qrBruno] (bloqueada), ou os números [numeros] de cada um.
/// Qualquer outro é um QR Code (ou número) não reconhecido.
class OperadorRepositorioMock implements OperadorRepositorio {
  static const qrMarina = 'qr-marina';
  static const qrCarla = 'qr-carla';
  static const qrBruno = 'qr-bruno';

  /// Número impresso na carteirinha → QR Code da mesma carteirinha.
  static const numeros = {'38F29DBA': qrMarina, '2DA179EE': qrCarla, '7C01B4F2': qrBruno};

  /// Simula a falta de conexão nas próximas chamadas.
  bool semConexao = false;

  /// Leituras registradas em cada local, a mais recente primeiro.
  final registros = <String, List<RegistroCheckin>>{};

  @override
  Future<List<UnidadeEvento>> locais() async {
    if (semConexao) throw Exception('sem conexão');
    final hoje = Datas.hoje();
    return [
      UnidadeEvento(
        id: 'e3',
        nome: 'Clínica de Tênis',
        tipo: TipoLocal.evento,
        localizacao: 'Quadra 2 da Sede',
        dataInicio: hoje,
        dataFim: hoje.add(const Duration(days: 1)),
        planoIds: const [],
      ),
      const UnidadeEvento(
        id: 'e1',
        nome: 'Sede Central',
        tipo: TipoLocal.unidade,
        localizacao: 'Rua das Flores, 100 - Centro',
        planoIds: [],
      ),
    ];
  }

  @override
  Future<ResultadoCheckin> registrar({required String localId, required IdentificacaoCarteirinha carteirinha}) async {
    if (semConexao) throw Exception('sem conexão');
    final (codigo, forma) = switch (carteirinha) {
      PorQr(:final codigo) => (codigo, FormaCheckin.qr),
      PorNumero(:final numero) => (numeros[numero.toUpperCase()], FormaCheckin.numero),
    };
    final agora = DateTime.now();
    final hoje = Datas.hoje();
    final membro = switch (codigo) {
      qrMarina => MembroLido(
        nome: 'Marina Membro',
        numero: '38F29DBA',
        planoNome: 'Mensal',
        planoCor: '#3A9FE0',
        dataVencimento: hoje.add(const Duration(days: 20)),
      ),
      qrCarla => MembroLido(
        nome: 'Carla Dias',
        numero: '2DA179EE',
        planoNome: 'Trimestral',
        planoCor: '#9C6ADE',
        dataVencimento: hoje.subtract(const Duration(days: 10)),
      ),
      qrBruno => MembroLido(
        nome: 'Bruno Souza',
        numero: '7C01B4F2',
        planoNome: 'Mensal',
        planoCor: '#3A9FE0',
        dataVencimento: hoje.add(const Duration(days: 4)),
      ),
      _ => null,
    };

    final motivo = membro == null
        ? (forma == FormaCheckin.qr ? MotivoRecusa.qrInvalido : MotivoRecusa.numeroInvalido)
        : (codigo == qrBruno ? MotivoRecusa.carteirinhaBloqueada : null);
    final mensagem = switch (motivo) {
      MotivoRecusa.qrInvalido => 'QR Code não reconhecido como carteirinha desta organização.',
      MotivoRecusa.numeroInvalido => 'Nenhuma carteirinha desta organização com este número.',
      MotivoRecusa.carteirinhaBloqueada => 'Carteirinha bloqueada pela administração.',
      _ => null,
    };
    final vencida = membro != null && membro.dataVencimento.isBefore(hoje);
    final doLocal = registros.putIfAbsent(localId, () => []);
    final anterior = motivo != null
        ? null
        : doLocal.where((r) => r.aprovado && r.membroNome == membro!.nome).firstOrNull?.dataHora;

    doLocal.insert(
      0,
      RegistroCheckin(
        id: '$localId-${doLocal.length + 1}',
        dataHora: agora,
        aprovado: motivo == null,
        motivo: motivo,
        mensagem: mensagem,
        vencida: vencida,
        forma: forma,
        membroNome: membro?.nome,
        planoNome: membro?.planoNome,
        planoCor: membro?.planoCor,
      ),
    );
    return ResultadoCheckin(
      dataHora: agora,
      aprovado: motivo == null,
      motivo: motivo,
      mensagem: mensagem,
      vencida: vencida,
      forma: forma,
      entradaAnteriorHoje: anterior,
      membro: membro,
    );
  }

  @override
  Future<List<RegistroCheckin>> checkinsDeHoje(String localId) async {
    if (semConexao) throw Exception('sem conexão');
    return List.of(registros[localId] ?? const []);
  }
}
