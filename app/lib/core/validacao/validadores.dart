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
}
