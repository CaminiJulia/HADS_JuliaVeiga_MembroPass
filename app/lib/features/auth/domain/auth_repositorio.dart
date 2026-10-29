import 'usuario.dart';

/// Contrato de autenticação. Hoje é atendido por [AuthRepositorioMock];
/// quando a API NestJS estiver pronta, basta trocar a implementação.
abstract interface class AuthRepositorio {
  /// Autentica pelo e-mail e senha. O papel é descoberto pelo cadastro
  /// em que o e-mail for encontrado (RF01).
  ///
  /// Lança [CredenciaisInvalidasException] se o e-mail ou a senha não conferem.
  Future<Usuario> entrar({required String email, required String senha});

  /// Solicita o envio do link de redefinição de senha (HU03).
  Future<void> solicitarRecuperacaoSenha(String email);
}

class CredenciaisInvalidasException implements Exception {
  const CredenciaisInvalidasException();
}
