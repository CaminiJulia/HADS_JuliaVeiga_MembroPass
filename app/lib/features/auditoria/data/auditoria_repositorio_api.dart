import '../../../core/api/cliente_api.dart';
import '../domain/registro_auditoria.dart';

class AuditoriaRepositorioApi implements AuditoriaRepositorio {
  AuditoriaRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<List<RegistroAuditoria>> listar() async {
    final lista = await _api.get('/auditoria') as List<dynamic>;
    return [for (final item in lista) RegistroAuditoria.deJson(item as Map<String, dynamic>)];
  }
}
