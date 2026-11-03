/// Conversão entre número e texto em reais, no formato brasileiro.
abstract final class Moeda {
  /// 1234.5 → "R$ 1.234,50"
  static String formatar(num valor) {
    final centavos = (valor * 100).round();
    final reais = (centavos ~/ 100).toString();
    final milhares = reais.replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => '.');
    final resto = (centavos % 100).toString().padLeft(2, '0');
    return 'R\$ $milhares,$resto';
  }

  /// Valor sem o "R$", para preencher o campo de edição: 1234.5 → "1234,50"
  static String paraCampo(num valor) => valor.toStringAsFixed(2).replaceAll('.', ',');

  /// "1.234,50", "1234,5" ou "1234" → 1234.5. Devolve `null` se não for um valor válido.
  static double? ler(String texto) {
    final limpo = texto.replaceAll('R\$', '').replaceAll(' ', '').replaceAll('.', '');
    if (!RegExp(r'^\d+(,\d{1,2})?$').hasMatch(limpo)) return null;
    return double.parse(limpo.replaceAll(',', '.'));
  }
}
