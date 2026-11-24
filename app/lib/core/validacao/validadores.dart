/// Validadores reutilizáveis de formulário (RNF16).
/// Cada função devolve a mensagem de erro, ou `null` quando o valor é válido.
abstract final class Validadores {
  static final _formatoEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe seu e-mail.';
    if (!_formatoEmail.hasMatch(texto)) return 'Informe um e-mail válido.';
    return null;
  }

  static String? senha(String? valor) {
    if (valor == null || valor.isEmpty) return 'Informe sua senha.';
    return null;
  }

  /// Mesmas regras da API para toda senha nova: 8+ caracteres, letras e números.
  static String? novaSenha(String? valor) {
    final s = valor ?? '';
    if (s.length < 8) return 'Use pelo menos 8 caracteres.';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) return 'Use letras e números.';
    return null;
  }
}
