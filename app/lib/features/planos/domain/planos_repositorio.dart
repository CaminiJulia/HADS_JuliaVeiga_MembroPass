import 'plano.dart';

/// Planos da organização do administrador logado (RF04).
/// Em caso de erro, lança `ErroApi` com a mensagem pronta para exibir.
abstract interface class PlanosRepositorio {
  Future<List<Plano>> listar();
  Future<Plano> criar(DadosPlano dados);
  Future<Plano> editar(String id, DadosPlano dados);
  Future<Plano> alterarAtivo(String id, {required bool ativo});
}
