import '../../../core/api/cliente_api.dart';
import '../domain/auth_repositorio.dart';
import '../domain/papel.dart';
import '../domain/usuario.dart';

/// Implementação provisória, sem API, com uma conta de teste por papel.
/// Senha de todas as contas: `Senha@123`. [novoOperador] entra com a senha
/// provisória [senhaProvisoria]. O código de recuperação é sempre [codigo].
class AuthRepositorioMock implements AuthRepositorio {
  AuthRepositorioMock({this.latencia = const Duration(milliseconds: 700)});

  /// Simula o tempo de resposta da rede.
  final Duration latencia;

  static const senhaPadrao = 'Senha@123';
  static const senhaProvisoria = 'Prov5678';
  static const codigo = '123456';

  static const novoOperador = Usuario(
    id: 'op-2',
    nome: 'Paula Portaria',
    email: 'novo@membropass.dev',
    papel: Papel.operador,
    organizacaoId: 'org-1',
    organizacaoNome: 'Clube Exemplo',
    senhaProvisoria: true,
  );

  /// Senhas trocadas nos testes, por e-mail.
  final _senhas = <String, String>{};
  Usuario? _logado;

  static const contas = <Usuario>[
    Usuario(
      id: 'adm-1',
      nome: 'Ana Administradora',
      email: 'admin@membropass.dev',
      papel: Papel.administrador,
      organizacaoId: 'org-1',
      organizacaoNome: 'Clube Exemplo',
    ),
    Usuario(
      id: 'op-1',
      nome: 'Otávio Operador',
      email: 'operador@membropass.dev',
      papel: Papel.operador,
      organizacaoId: 'org-1',
      organizacaoNome: 'Clube Exemplo',
    ),
    Usuario(
      id: 'mem-1',
      nome: 'Marina Membro',
      email: 'membro@membropass.dev',
      papel: Papel.membro,
      organizacaoId: 'org-1',
      organizacaoNome: 'Clube Exemplo',
    ),
  ];

  @override
  Future<Usuario> entrar({required String email, required String senha}) async {
    await Future<void>.delayed(latencia);
    final emailNormalizado = email.trim().toLowerCase();
    if (emailNormalizado == novoOperador.email) {
      final trocada = _senhas[novoOperador.email];
      if (senha == (trocada ?? senhaProvisoria)) {
        return _logado = trocada == null ? novoOperador : _semProvisoria(novoOperador);
      }
      throw const CredenciaisInvalidasException();
    }
    for (final conta in contas) {
      if (conta.email == emailNormalizado && senha == (_senhas[conta.email] ?? senhaPadrao)) return _logado = conta;
    }
    throw const CredenciaisInvalidasException();
  }

  @override
  Future<void> solicitarRecuperacaoSenha(String email) async {
    await Future<void>.delayed(latencia);
  }

  @override
  Future<void> redefinirSenha({required String email, required String codigo, required String novaSenha}) async {
    if (codigo != AuthRepositorioMock.codigo) {
      throw const ErroApi(400, 'Código incorreto. Confira o e-mail e tente de novo.');
    }
    _senhas[email.trim().toLowerCase()] = novaSenha;
  }

  @override
  Future<void> trocarSenha({required String senhaAtual, required String novaSenha}) async {
    final conta = _logado!;
    final atual = _senhas[conta.email] ?? (conta.senhaProvisoria ? senhaProvisoria : senhaPadrao);
    if (senhaAtual != atual) throw const ErroApi(400, 'A senha atual está incorreta.');
    _senhas[conta.email] = novaSenha;
  }

  static Usuario _semProvisoria(Usuario u) => Usuario(
    id: u.id,
    nome: u.nome,
    email: u.email,
    papel: u.papel,
    organizacaoId: u.organizacaoId,
    organizacaoNome: u.organizacaoNome,
  );

  @override
  void sair() => _logado = null;
}
