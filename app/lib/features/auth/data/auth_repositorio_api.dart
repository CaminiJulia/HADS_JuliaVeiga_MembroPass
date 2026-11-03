import '../../../core/api/cliente_api.dart';
import '../domain/auth_repositorio.dart';
import '../domain/papel.dart';
import '../domain/usuario.dart';

/// Autenticação pela API NestJS (`api/`).
class AuthRepositorioApi implements AuthRepositorio {
  AuthRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<Usuario> entrar({required String email, required String senha}) async {
    try {
      final corpo = await _api.post('/auth/login', {'email': email.trim(), 'senha': senha})
          as Map<String, dynamic>;
      _api.token = corpo['token'] as String;
      final usuario = corpo['usuario'] as Map<String, dynamic>;
      return Usuario(
        id: usuario['id'] as String,
        nome: usuario['nome'] as String,
        email: usuario['email'] as String,
        papel: Papel.values.byName(usuario['papel'] as String),
        organizacaoId: usuario['organizacaoId'] as String,
        organizacaoNome: usuario['organizacaoNome'] as String,
      );
    } on ErroApi catch (e) {
      throw switch (e.status) {
        400 || 401 => const CredenciaisInvalidasException(),
        429 => TentativasEsgotadasException(e.mensagem),
        _ => e,
      };
    }
  }

  @override
  Future<void> solicitarRecuperacaoSenha(String email) async {
    await _api.post('/auth/recuperar-senha', {'email': email.trim()});
  }

  @override
  void sair() => _api.token = null;
}
