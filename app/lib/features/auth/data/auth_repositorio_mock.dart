import '../domain/auth_repositorio.dart';
import '../domain/papel.dart';
import '../domain/usuario.dart';

/// Implementação provisória, sem API, com uma conta de teste por papel.
/// Senha de todas as contas: `Senha@123`.
class AuthRepositorioMock implements AuthRepositorio {
  AuthRepositorioMock({this.latencia = const Duration(milliseconds: 700)});

  /// Simula o tempo de resposta da rede.
  final Duration latencia;

  static const senhaPadrao = 'Senha@123';

  static const contas = <Usuario>[
    Usuario(
      id: 'adm-1',
      nome: 'Ana Administradora',
      email: 'admin@membropass.dev',
      papel: Papel.administrador,
      organizacaoId: 'org-1',
    ),
    Usuario(
      id: 'op-1',
      nome: 'Otávio Operador',
      email: 'operador@membropass.dev',
      papel: Papel.operador,
      organizacaoId: 'org-1',
    ),
    Usuario(
      id: 'mem-1',
      nome: 'Marina Membro',
      email: 'membro@membropass.dev',
      papel: Papel.membro,
      organizacaoId: 'org-1',
    ),
  ];

  @override
  Future<Usuario> entrar({required String email, required String senha}) async {
    await Future<void>.delayed(latencia);
    final emailNormalizado = email.trim().toLowerCase();
    for (final conta in contas) {
      if (conta.email == emailNormalizado && senha == senhaPadrao) return conta;
    }
    throw const CredenciaisInvalidasException();
  }

  @override
  Future<void> solicitarRecuperacaoSenha(String email) async {
    await Future<void>.delayed(latencia);
  }
}
