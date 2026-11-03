import '../../auditoria/domain/registro_auditoria.dart';
import 'membro.dart';

/// Membros da organização do administrador logado (RF06, RF07).
/// Em caso de erro, lança `ErroApi` com a mensagem pronta para exibir.
abstract interface class MembrosRepositorio {
  Future<List<Membro>> listar();
  Future<Membro> buscar(String id);
  Future<MembroCriado> criar(DadosMembro dados);
  Future<Membro> editar(String id, DadosMembro dados);
  Future<Membro> alterarAtivo(String id, {required bool ativo, String? justificativa});

  /// Confirma o pagamento feito em [dataPagamento] e libera um novo ciclo.
  Future<Membro> confirmarPagamento(String id, DateTime dataPagamento);
  Future<Membro> bloquear(String id, String justificativa);
  Future<Membro> desbloquear(String id);

  /// Ações da auditoria sobre este membro, da mais recente para a mais antiga.
  Future<List<RegistroAuditoria>> historico(String id);
}
