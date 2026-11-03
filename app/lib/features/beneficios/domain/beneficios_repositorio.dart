import 'beneficio.dart';

/// Benefícios da organização do administrador logado (RF08).
/// Em caso de erro, lança `ErroApi` com a mensagem pronta para exibir.
abstract interface class BeneficiosRepositorio {
  Future<List<Beneficio>> listar();
  Future<Beneficio> criar(DadosBeneficio dados);
  Future<Beneficio> editar(String id, DadosBeneficio dados);
  Future<void> excluir(String id);
}
