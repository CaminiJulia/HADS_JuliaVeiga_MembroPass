import '../../../core/api/cliente_api.dart';
import '../../../core/formatacao/datas.dart';
import '../../auditoria/domain/registro_auditoria.dart';
import '../domain/membro.dart';
import '../domain/membros_repositorio.dart';

class MembrosRepositorioApi implements MembrosRepositorio {
  MembrosRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<List<Membro>> listar() async {
    final lista = await _api.get('/membros') as List<dynamic>;
    return [for (final item in lista) Membro.deJson(item as Map<String, dynamic>)];
  }

  @override
  Future<Membro> buscar(String id) async => _membro(await _api.get('/membros/$id'));

  @override
  Future<MembroCriado> criar(DadosMembro dados) async {
    final json = await _api.post('/membros', dados.paraJson()) as Map<String, dynamic>;
    return MembroCriado(_membro(json['membro']), json['senhaProvisoria'] as String);
  }

  @override
  Future<Membro> editar(String id, DadosMembro dados) async =>
      _membro(await _api.put('/membros/$id', dados.paraJson()));

  @override
  Future<Membro> alterarAtivo(String id, {required bool ativo, String? justificativa}) async => _membro(
    await _api.patch('/membros/$id/status', {'status': ativo ? 'ATIVO' : 'DESATIVADO', 'justificativa': justificativa}),
  );

  @override
  Future<Membro> confirmarPagamento(String id, DateTime dataPagamento) async =>
      _membro(await _api.post('/membros/$id/liberar-ciclo', {'dataPagamento': Datas.paraApi(dataPagamento)}));

  @override
  Future<Membro> bloquear(String id, String justificativa) async =>
      _membro(await _api.post('/membros/$id/bloquear', {'justificativa': justificativa}));

  @override
  Future<Membro> desbloquear(String id) async => _membro(await _api.post('/membros/$id/desbloquear', {}));

  @override
  Future<List<RegistroAuditoria>> historico(String id) async {
    final lista = await _api.get('/membros/$id/historico') as List<dynamic>;
    return [for (final item in lista) RegistroAuditoria.deJson(item as Map<String, dynamic>)];
  }

  static Membro _membro(dynamic json) => Membro.deJson(json as Map<String, dynamic>);
}
