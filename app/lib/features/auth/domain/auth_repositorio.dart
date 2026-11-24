import 'usuario.dart';

/// Contrato de autenticação. O app usa [AuthRepositorioApi]; os testes
/// usam [AuthRepositorioMock], que não depende da API.
abstract interface class AuthRepositorio {
  /// Autentica pelo e-mail e senha. O papel é descoberto pelo cadastro
  /// em que o e-mail for encontrado (RF01).
  ///
  /// Lança [CredenciaisInvalidasException] se o e-mail ou a senha não conferem.
  Future<Usuario> entrar({required String email, required String senha});

  /// Envia um código de 6 dígitos para o e-mail (HU03). A resposta é a mesma
  /// exista ou não o cadastro.
  Future<void> solicitarRecuperacaoSenha(String email);

  /// Cria uma senha nova com o código recebido por e-mail. Lança `ErroApi`
  /// com a mensagem pronta se o código estiver errado ou vencido.
  Future<void> redefinirSenha({required String email, required String codigo, required String novaSenha});

  /// Troca a senha de quem está logado (inclusive a provisória). As outras
  /// sessões são encerradas; esta continua com um token novo.
  Future<void> trocarSenha({required String senhaAtual, required String novaSenha});

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
