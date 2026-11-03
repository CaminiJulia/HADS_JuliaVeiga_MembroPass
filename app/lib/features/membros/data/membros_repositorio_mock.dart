import '../../../core/api/cliente_api.dart';
import '../../../core/formatacao/datas.dart';
import '../domain/membro.dart';
import '../domain/membros_repositorio.dart';

/// Membros em memória, para os testes rodarem sem a API.
/// Os ids de plano batem com os do `PlanosRepositorioMock` (p1 = Mensal, p2 = Anual).
class MembrosRepositorioMock implements MembrosRepositorio {
  MembrosRepositorioMock({DateTime? hoje}) : _hoje = hoje ?? Datas.hoje() {
    _membros.addAll([
      _novo('m1', 'Marina Membro', 'membro@membropass.dev', 'p1', 'Mensal', vence: 20),
      _novo('m2', 'Bruno Souza', 'bruno@exemplo.com', 'p1', 'Mensal', vence: 4),
      _novo('m3', 'Carla Dias', 'carla@exemplo.com', 'p2', 'Anual', vence: -10),
    ]);
  }

  static const senhaProvisoria = 'Prov1234';
  static const _nomesPlanos = {'p1': 'Mensal', 'p2': 'Anual'};

  final DateTime _hoje;
  final _membros = <Membro>[];
  var _proximoId = 4;

  @override
  Future<List<Membro>> listar() async => List.of(_membros);

  @override
  Future<Membro> buscar(String id) async => _membros[_indice(id)];

  @override
  Future<MembroCriado> criar(DadosMembro dados) async {
    _exigirEmailUnico(dados.email);
    final membro = _novo(
      'm${_proximoId++}',
      dados.nome,
      dados.email,
      dados.planoId,
      _nomesPlanos[dados.planoId]!,
      vence: 30,
      telefone: dados.telefone,
    );
    _membros.add(membro);
    return MembroCriado(membro, senhaProvisoria);
  }

  @override
  Future<Membro> editar(String id, DadosMembro dados) async {
    _exigirEmailUnico(dados.email, ignorarId: id);
    return _alterar(
      id,
      (m) => Membro(
        id: m.id,
        nome: dados.nome,
        email: dados.email,
        telefone: dados.telefone,
        planoId: dados.planoId,
        planoNome: _nomesPlanos[dados.planoId]!,
        dataAdesao: m.dataAdesao,
        ativo: m.ativo,
        carteirinha: m.carteirinha,
      ),
    );
  }

  @override
  Future<Membro> alterarAtivo(String id, {required bool ativo}) async => _alterar(
        id,
        (m) => Membro(
          id: m.id,
          nome: m.nome,
          email: m.email,
          telefone: m.telefone,
          planoId: m.planoId,
          planoNome: m.planoNome,
          dataAdesao: m.dataAdesao,
          ativo: ativo,
          carteirinha: Carteirinha(
            status: ativo ? StatusCarteirinha.ativa : StatusCarteirinha.invalidada,
            dataVencimento: m.carteirinha.dataVencimento,
            qrVersao: m.carteirinha.qrVersao + 1,
          ),
        ),
      );

  Membro _alterar(String id, Membro Function(Membro) alteracao) {
    final i = _indice(id);
    return _membros[i] = alteracao(_membros[i]);
  }

  int _indice(String id) {
    final i = _membros.indexWhere((m) => m.id == id);
    if (i < 0) throw const ErroApi(404, 'Membro não encontrado.');
    return i;
  }

  void _exigirEmailUnico(String email, {String? ignorarId}) {
    if (_membros.any((m) => m.id != ignorarId && m.email == email.trim().toLowerCase())) {
      throw const ErroApi(409, 'Este e-mail já está em uso por outra conta.');
    }
  }

  Membro _novo(
    String id,
    String nome,
    String email,
    String planoId,
    String planoNome, {
    required int vence,
    String? telefone,
  }) =>
      Membro(
        id: id,
        nome: nome,
        email: email.trim().toLowerCase(),
        telefone: telefone,
        planoId: planoId,
        planoNome: planoNome,
        dataAdesao: _hoje.subtract(const Duration(days: 30)),
        ativo: true,
        carteirinha: Carteirinha(
          status: StatusCarteirinha.ativa,
          dataVencimento: _hoje.add(Duration(days: vence)),
          qrVersao: 1,
        ),
      );
}
