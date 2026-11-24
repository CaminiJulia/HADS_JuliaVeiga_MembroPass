import '../../../core/api/cliente_api.dart';
import '../domain/operador.dart';

class OperadoresRepositorioApi implements OperadoresRepositorio {
  OperadoresRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<List<Operador>> listar() async => [
    for (final o in await _api.get('/operadores') as List) Operador.deJson(o as Map<String, dynamic>),
  ];

  @override
  Future<OperadorCriado> criar(DadosOperador dados) async {
    final json = await _api.post('/operadores', dados.paraJson()) as Map<String, dynamic>;
    return OperadorCriado(
      Operador.deJson(json['operador'] as Map<String, dynamic>),
      json['senhaProvisoria'] as String,
      emailEnviado: json['emailEnviado'] as bool? ?? false,
    );
  }

  @override
  Future<Operador> editar(String id, DadosOperador dados) async =>
      Operador.deJson(await _api.put('/operadores/$id', dados.paraJson()) as Map<String, dynamic>);

  @override
  Future<Operador> alterarStatus(String id, {required bool ativo}) async => Operador.deJson(
    await _api.patch('/operadores/$id/status', {'status': ativo ? 'ATIVO' : 'INATIVO'}) as Map<String, dynamic>,
  );

  @override
  Future<SenhaGerada> novaSenha(String id) async {
    final json = await _api.post('/operadores/$id/nova-senha', const {}) as Map<String, dynamic>;
    return (senha: json['senhaProvisoria'] as String, emailEnviado: json['emailEnviado'] as bool? ?? false);
  }
}

/// Operadores em memória, para os testes rodarem sem a API.
class OperadoresRepositorioMock implements OperadoresRepositorio {
  static const senhaProvisoria = 'Prov5678';

  final _operadores = <Operador>[
    Operador(
      id: 'op-1',
      nome: 'Otávio Operador',
      email: 'operador@membropass.dev',
      checkinsHoje: 12,
      ultimoCheckin: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  /// E-mails que já são de outra conta (admin e membro dos dados de teste).
  static const _emailsDeOutros = {'admin@membropass.dev', 'membro@membropass.dev'};

  void _exigirEmailLivre(String email, {String? exceto}) {
    final usado =
        _emailsDeOutros.contains(email) || _operadores.any((o) => o.id != exceto && o.email == email.toLowerCase());
    if (usado) throw const ErroApi(409, 'Este e-mail já está em uso por outra conta.');
  }

  @override
  Future<List<Operador>> listar() async => List.of(_operadores);

  @override
  Future<OperadorCriado> criar(DadosOperador dados) async {
    _exigirEmailLivre(dados.email);
    final novo = Operador(
      id: 'op-${_operadores.length + 1}',
      nome: dados.nome,
      email: dados.email.toLowerCase(),
      telefone: dados.telefone,
    );
    _operadores.add(novo);
    return OperadorCriado(novo, senhaProvisoria, emailEnviado: true);
  }

  @override
  Future<Operador> editar(String id, DadosOperador dados) async {
    _exigirEmailLivre(dados.email, exceto: id);
    return _trocar(
      id,
      (o) => Operador(
        id: o.id,
        nome: dados.nome,
        email: dados.email.toLowerCase(),
        telefone: dados.telefone,
        ativo: o.ativo,
        foto: o.foto,
        checkinsHoje: o.checkinsHoje,
        ultimoCheckin: o.ultimoCheckin,
      ),
    );
  }

  @override
  Future<Operador> alterarStatus(String id, {required bool ativo}) async =>
      _trocar(id, (o) => o.copiarCom(ativo: ativo));

  @override
  Future<SenhaGerada> novaSenha(String id) async => (senha: senhaProvisoria, emailEnviado: true);

  Operador _trocar(String id, Operador Function(Operador) mudar) {
    final i = _operadores.indexWhere((o) => o.id == id);
    return _operadores[i] = mudar(_operadores[i]);
  }
}
