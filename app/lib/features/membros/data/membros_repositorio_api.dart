import '../../../core/api/cliente_api.dart';
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
  Future<Membro> buscar(String id) async =>
      Membro.deJson(await _api.get('/membros/$id') as Map<String, dynamic>);

  @override
  Future<MembroCriado> criar(DadosMembro dados) async {
    final json = await _api.post('/membros', dados.paraJson()) as Map<String, dynamic>;
    return MembroCriado(
      Membro.deJson(json['membro'] as Map<String, dynamic>),
      json['senhaProvisoria'] as String,
    );
  }

  @override
  Future<Membro> editar(String id, DadosMembro dados) async =>
      Membro.deJson(await _api.put('/membros/$id', dados.paraJson()) as Map<String, dynamic>);

  @override
  Future<Membro> alterarAtivo(String id, {required bool ativo}) async => Membro.deJson(
        await _api.patch('/membros/$id/status', {'status': ativo ? 'ATIVO' : 'DESATIVADO'})
            as Map<String, dynamic>,
      );
}
