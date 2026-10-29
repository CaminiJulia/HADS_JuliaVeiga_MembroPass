import 'usuario.dart';

/// Contrato da autenticação. A tela de login depende só desta interface,
/// então trocar a implementação simulada pela chamada à API não muda a tela.
abstract interface class AuthRepositorio {
  /// Autentica pelo e-mail e senha. Lança [ErroLogin] quando não consegue.
  Future<Usuario> entrar({required String email, required String senha});
}

sealed class ErroLogin implements Exception {
  const ErroLogin(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class CredenciaisInvalidas extends ErroLogin {
  const CredenciaisInvalidas() : super('E-mail ou senha incorretos.');
}

/// RF01: o acesso é bloqueado temporariamente após várias tentativas inválidas.
class AcessoBloqueado extends ErroLogin {
  AcessoBloqueado(this.liberaEm)
    : super(
        'Muitas tentativas sem sucesso. '
        'Tente novamente em ${liberaEm.inMinutes < 1 ? 1 : liberaEm.inMinutes} min.',
      );

  final Duration liberaEm;
}

class FalhaDeConexao extends ErroLogin {
  const FalhaDeConexao()
    : super('Não foi possível conectar. Verifique sua internet e tente de novo.');
}
