import '../../../core/api/cliente_api.dart';
import '../domain/unidade_evento.dart';

class UnidadesRepositorioApi implements UnidadesRepositorio {
  UnidadesRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<List<UnidadeEvento>> listar() async {
    final lista = await _api.get('/unidades-eventos') as List<dynamic>;
    return [for (final item in lista) UnidadeEvento.deJson(item as Map<String, dynamic>)];
  }

  @override
  Future<UnidadeEvento> criar(DadosUnidadeEvento dados) async =>
      UnidadeEvento.deJson(await _api.post('/unidades-eventos', dados.paraJson()) as Map<String, dynamic>);

  @override
  Future<UnidadeEvento> editar(String id, DadosUnidadeEvento dados) async =>
      UnidadeEvento.deJson(await _api.put('/unidades-eventos/$id', dados.paraJson()) as Map<String, dynamic>);

  @override
  Future<void> excluir(String id) => _api.delete('/unidades-eventos/$id');
}
