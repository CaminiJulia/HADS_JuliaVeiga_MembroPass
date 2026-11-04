import '../../../core/api/cliente_api.dart';
import '../../../core/formatacao/datas.dart';
import '../../beneficios/domain/beneficio.dart';
import '../../membros/domain/membro.dart';
import '../../unidades/domain/unidade_evento.dart';
import '../domain/carteirinha_membro.dart';

class AreaMembroRepositorioApi implements AreaMembroRepositorio {
  AreaMembroRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<CarteirinhaMembro> carteirinha() async =>
      CarteirinhaMembro.deJson(await _api.get('/membro/carteirinha') as Map<String, dynamic>);

  @override
  Future<List<Beneficio>> beneficios() async => [
    for (final b in await _api.get('/membro/beneficios') as List) Beneficio.deJson(b as Map<String, dynamic>),
  ];

  @override
  Future<List<UnidadeEvento>> locais() async => [
    for (final u in await _api.get('/membro/locais') as List) UnidadeEvento.deJson(u as Map<String, dynamic>),
  ];
}

/// Área do membro em memória, para os testes rodarem sem a API.
class AreaMembroRepositorioMock implements AreaMembroRepositorio {
  AreaMembroRepositorioMock({this.status = StatusCarteirinha.ativa, this.diasParaVencer = 20});

  /// Situação simulada, para testar bloqueio e vencimento.
  StatusCarteirinha status;
  int diasParaVencer;

  /// Quantas vezes a carteirinha foi buscada (o QR é renovado a cada busca).
  int buscas = 0;

  /// Simula a falta de conexão nas próximas buscas.
  bool semConexao = false;

  @override
  Future<CarteirinhaMembro> carteirinha() async {
    buscas++;
    if (semConexao) throw Exception('sem conexão');
    final hoje = Datas.hoje();
    final ativa = status == StatusCarteirinha.ativa;
    return CarteirinhaMembro(
      nomeMembro: 'Marina Membro',
      planoNome: 'Mensal',
      planoCor: '#3A9FE0',
      numero: '38F29DBA',
      status: status,
      dataEmissao: hoje.subtract(const Duration(days: 10)),
      dataVencimento: hoje.add(Duration(days: diasParaVencer)),
      qrCodigo: ativa ? 'qr-de-teste-$buscas' : null,
      qrExpiraEm: ativa ? DateTime.now().add(const Duration(minutes: 5)) : null,
    );
  }

  @override
  Future<List<Beneficio>> beneficios() async => const [
    Beneficio(
      id: 'b1',
      nome: 'Desconto na farmácia',
      descricao: 'Apresente a carteirinha no caixa.',
      parceiro: 'Farmácia Central',
      tipoDesconto: TipoDesconto.percentual,
      valorDesconto: 15,
      planoIds: [],
    ),
  ];

  @override
  Future<List<UnidadeEvento>> locais() async => const [
    UnidadeEvento(
      id: 'e1',
      nome: 'Sede Central',
      tipo: TipoLocal.unidade,
      localizacao: 'Rua das Flores, 100 - Centro',
      planoIds: [],
    ),
  ];
}
