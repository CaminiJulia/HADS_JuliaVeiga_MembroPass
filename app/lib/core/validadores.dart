/// Validações de formulário reutilizáveis (RNF16).
/// Cada função segue a assinatura do `validator` do Flutter:
/// devolve `null` quando o valor é válido ou a mensagem de erro.
abstract final class Validadores {
  static final _formatoEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe seu e-mail.';
    if (!_formatoEmail.hasMatch(texto)) return 'E-mail inválido.';
    return null;
  }

  static String? obrigatorio(String? valor, {String campo = 'este campo'}) {
    if (valor == null || valor.isEmpty) return 'Informe $campo.';
    return null;
  }
}
