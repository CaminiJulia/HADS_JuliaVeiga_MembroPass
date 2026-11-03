import '../../../core/api/cliente_api.dart';
import '../domain/beneficio.dart';
import '../domain/beneficios_repositorio.dart';

class BeneficiosRepositorioApi implements BeneficiosRepositorio {
  BeneficiosRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<List<Beneficio>> listar() async {
    final lista = await _api.get('/beneficios') as List<dynamic>;
    return [for (final item in lista) Beneficio.deJson(item as Map<String, dynamic>)];
  }

  @override
  Future<Beneficio> criar(DadosBeneficio dados) async =>
      Beneficio.deJson(await _api.post('/beneficios', dados.paraJson()) as Map<String, dynamic>);

  @override
  Future<Beneficio> editar(String id, DadosBeneficio dados) async =>
      Beneficio.deJson(await _api.put('/beneficios/$id', dados.paraJson()) as Map<String, dynamic>);

  @override
  Future<void> excluir(String id) => _api.delete('/beneficios/$id');
}
