import '../../../core/api/cliente_api.dart';
import '../domain/plano.dart';
import '../domain/planos_repositorio.dart';

class PlanosRepositorioApi implements PlanosRepositorio {
  PlanosRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<List<Plano>> listar() async {
    final lista = await _api.get('/planos') as List<dynamic>;
    return [for (final item in lista) Plano.deJson(item as Map<String, dynamic>)];
  }

  @override
  Future<Plano> criar(DadosPlano dados) async =>
      Plano.deJson(await _api.post('/planos', dados.paraJson()) as Map<String, dynamic>);

  @override
  Future<Plano> editar(String id, DadosPlano dados) async =>
      Plano.deJson(await _api.put('/planos/$id', dados.paraJson()) as Map<String, dynamic>);

  @override
  Future<Plano> alterarAtivo(String id, {required bool ativo}) async => Plano.deJson(
    await _api.patch('/planos/$id/status', {'status': ativo ? 'ATIVO' : 'INATIVO'}) as Map<String, dynamic>,
  );
}
