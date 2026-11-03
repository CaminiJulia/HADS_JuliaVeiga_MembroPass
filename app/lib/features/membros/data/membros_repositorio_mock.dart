import '../../../core/api/cliente_api.dart';
import '../../../core/formatacao/datas.dart';
import '../../auditoria/domain/registro_auditoria.dart';
import '../domain/membro.dart';
import '../domain/membros_repositorio.dart';

/// Membros em memória, para os testes rodarem sem a API.
/// Os ids de plano batem com os do `PlanosRepositorioMock` (p1 = Mensal, p2 = Anual).
/// Também guarda a auditoria, que o `AuditoriaRepositorioMock` lê.
class MembrosRepositorioMock implements MembrosRepositorio {
  MembrosRepositorioMock({DateTime? hoje}) : _hoje = hoje ?? Datas.hoje() {
    _membros.addAll([
      _novo('m1', 'Marina Membro', 'membro@membropass.dev', 'p1', vence: 20),
      _novo('m2', 'Bruno Souza', 'bruno@exemplo.com', 'p1', vence: 4),
      _novo('m3', 'Carla Dias', 'carla@exemplo.com', 'p2', vence: -10),
    ]);
  }

  static const senhaProvisoria = 'Prov1234';
  static const _planos = {'p1': ('Mensal', 30, '#3A9FE0'), 'p2': ('Anual', 365, null)};

  final DateTime _hoje;
  final _membros = <Membro>[];

  /// Ações registradas, da mais recente para a mais antiga.
  final auditoria = <(String membroId, RegistroAuditoria registro)>[];
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
      vence: _planos[dados.planoId]!.$2,
      telefone: dados.telefone,
    );
    _membros.add(membro);
    return MembroCriado(membro, senhaProvisoria);
  }

  @override
  Future<Membro> editar(String id, DadosMembro dados) async {
    _exigirEmailUnico(dados.email, ignorarId: id);
    final m = _membros[_indice(id)];
    final (planoNome, duracao, planoCor) = _planos[dados.planoId]!;
    return _membros[_indice(id)] = Membro(
      id: m.id,
      nome: dados.nome,
      email: dados.email,
      telefone: dados.telefone,
      planoId: dados.planoId,
      planoNome: planoNome,
      planoDuracaoDias: duracao,
      planoCor: planoCor,
      dataAdesao: m.dataAdesao,
      ativo: m.ativo,
      carteirinha: m.carteirinha,
    );
  }

  @override
  Future<Membro> alterarAtivo(String id, {required bool ativo, String? justificativa}) async {
    final membro = _alterar(
      id,
      (m) => m.copyWith(
        ativo: ativo,
        carteirinha: _carteirinha(m, status: ativo ? StatusCarteirinha.ativa : StatusCarteirinha.invalidada),
      ),
    );
    _registrar(
      id,
      ativo ? AcaoAuditoria.reativacaoMembro : AcaoAuditoria.desativacaoMembro,
      'Cadastro de ${membro.nome} ${ativo ? 'reativado' : 'desativado'}.',
      justificativa,
    );
    return membro;
  }

  @override
  Future<Membro> confirmarPagamento(String id, DateTime dataPagamento) async {
    if (dataPagamento.isAfter(_hoje)) throw const ErroApi(400, 'A data do pagamento não pode ser futura.');
    final membro = _alterar(
      id,
      (m) => m.copyWith(
        carteirinha: _carteirinha(m, status: StatusCarteirinha.ativa, vencimento: m.novoVencimento(dataPagamento)),
      ),
    );
    _registrar(id, AcaoAuditoria.liberacaoCiclo, 'Pagamento de ${membro.nome} confirmado.', null);
    return membro;
  }

  @override
  Future<Membro> bloquear(String id, String justificativa) async {
    final membro = _alterar(id, (m) => m.copyWith(carteirinha: _carteirinha(m, status: StatusCarteirinha.bloqueada)));
    _registrar(id, AcaoAuditoria.bloqueioManual, 'Carteirinha de ${membro.nome} bloqueada.', justificativa);
    return membro;
  }

  @override
  Future<Membro> desbloquear(String id) async {
    final membro = _alterar(id, (m) => m.copyWith(carteirinha: _carteirinha(m, status: StatusCarteirinha.ativa)));
    _registrar(id, AcaoAuditoria.desbloqueio, 'Carteirinha de ${membro.nome} desbloqueada.', null);
    return membro;
  }

  @override
  Future<List<RegistroAuditoria>> historico(String id) async => [
    for (final (membroId, registro) in auditoria)
      if (membroId == id) registro,
  ];

  static Carteirinha _carteirinha(Membro m, {required StatusCarteirinha status, DateTime? vencimento}) => Carteirinha(
    status: status,
    dataVencimento: vencimento ?? m.carteirinha.dataVencimento,
    qrVersao: m.carteirinha.qrVersao + 1,
  );

  void _registrar(String membroId, AcaoAuditoria acao, String descricao, String? justificativa) {
    auditoria.insert(0, (
      membroId,
      RegistroAuditoria(
        id: 'a${auditoria.length + 1}',
        acao: acao,
        descricao: descricao,
        justificativa: justificativa,
        administradorNome: 'Ana Administradora',
        dataHora: DateTime.now(),
      ),
    ));
  }

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

  Membro _novo(String id, String nome, String email, String planoId, {required int vence, String? telefone}) {
    final (planoNome, duracao, planoCor) = _planos[planoId]!;
    return Membro(
      id: id,
      nome: nome,
      email: email.trim().toLowerCase(),
      telefone: telefone,
      planoId: planoId,
      planoNome: planoNome,
      planoDuracaoDias: duracao,
      planoCor: planoCor,
      dataAdesao: _hoje.subtract(const Duration(days: 30)),
      ativo: true,
      carteirinha: Carteirinha(
        status: StatusCarteirinha.ativa,
        dataVencimento: _hoje.add(Duration(days: vence)),
        qrVersao: 1,
      ),
    );
  }
}

/// Lê a auditoria guardada pelo [MembrosRepositorioMock].
class AuditoriaRepositorioMock implements AuditoriaRepositorio {
  AuditoriaRepositorioMock(this._membros);

  final MembrosRepositorioMock _membros;

  @override
  Future<List<RegistroAuditoria>> listar() async => [for (final (_, r) in _membros.auditoria) r];
}
