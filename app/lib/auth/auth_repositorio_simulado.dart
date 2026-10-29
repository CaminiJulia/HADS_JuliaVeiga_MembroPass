import 'auth_repositorio.dart';
import 'usuario.dart';

/// Implementação provisória, usada enquanto a API não existe.
/// Guarda três contas de teste em memória (uma por papel) e reproduz
/// o bloqueio temporário após tentativas inválidas.
///
/// Quando a API ficar pronta, ela assume essa responsabilidade e este
/// arquivo fica só para os testes.
class AuthRepositorioSimulado implements AuthRepositorio {
  AuthRepositorioSimulado({
    this.maxTentativas = 5,
    this.tempoBloqueio = const Duration(minutes: 15),
    this.atraso = const Duration(milliseconds: 600),
    DateTime Function()? relogio,
  }) : _agora = relogio ?? DateTime.now;

  static const senhaDeTeste = 'Senha@123';

  static const contas = [
    Usuario(id: 1, nome: 'Ana Admin', email: 'admin@membropass.dev', papel: Papel.administrador, organizacaoId: 1),
    Usuario(id: 1, nome: 'Otto Operador', email: 'operador@membropass.dev', papel: Papel.operador, organizacaoId: 1),
    Usuario(id: 1, nome: 'Maria Membro', email: 'membro@membropass.dev', papel: Papel.membro, organizacaoId: 1),
  ];

  final int maxTentativas;
  final Duration tempoBloqueio;

  /// Simula o tempo de resposta da rede, para a tela mostrar o carregamento.
  final Duration atraso;

  final DateTime Function() _agora;
  final _falhas = <String, int>{};
  final _bloqueadoAte = <String, DateTime>{};

  @override
  Future<Usuario> entrar({required String email, required String senha}) async {
    await Future<void>.delayed(atraso);
    final chave = email.trim().toLowerCase();

    final bloqueio = _bloqueadoAte[chave];
    if (bloqueio != null) {
      final restante = bloqueio.difference(_agora());
      if (restante > Duration.zero) throw AcessoBloqueado(restante);
      _bloqueadoAte.remove(chave);
      _falhas.remove(chave);
    }

    final conta = contas.where((c) => c.email == chave).firstOrNull;
    if (conta != null && senha == senhaDeTeste) {
      _falhas.remove(chave);
      return conta;
    }

    final falhas = (_falhas[chave] ?? 0) + 1;
    _falhas[chave] = falhas;
    if (falhas >= maxTentativas) {
      _bloqueadoAte[chave] = _agora().add(tempoBloqueio);
      throw AcessoBloqueado(tempoBloqueio);
    }
    throw const CredenciaisInvalidas();
  }
}
