import 'membro.dart';

/// Membros da organização do administrador logado (RF06).
/// Em caso de erro, lança `ErroApi` com a mensagem pronta para exibir.
abstract interface class MembrosRepositorio {
  Future<List<Membro>> listar();
  Future<Membro> buscar(String id);
  Future<MembroCriado> criar(DadosMembro dados);
  Future<Membro> editar(String id, DadosMembro dados);
  Future<Membro> alterarAtivo(String id, {required bool ativo});
}
