import 'usuario.dart';

/// Contrato de autenticação. O app usa [AuthRepositorioApi]; os testes
/// usam [AuthRepositorioMock], que não depende da API.
abstract interface class AuthRepositorio {
  /// Autentica pelo e-mail e senha. O papel é descoberto pelo cadastro
  /// em que o e-mail for encontrado (RF01).
  ///
  /// Lança [CredenciaisInvalidasException] se o e-mail ou a senha não conferem.
  Future<Usuario> entrar({required String email, required String senha});

  /// Solicita o envio do link de redefinição de senha (HU03).
  Future<void> solicitarRecuperacaoSenha(String email);

  /// Encerra a sessão (descarta o token do login).
  void sair();
}

class CredenciaisInvalidasException implements Exception {
  const CredenciaisInvalidasException();
}

/// A API bloqueou o e-mail por excesso de tentativas; [mensagem] vem dela.
class TentativasEsgotadasException implements Exception {
  const TentativasEsgotadasException(this.mensagem);

  final String mensagem;
}
