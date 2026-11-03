import 'dart:math';
import 'dart:ui';

/// RF17: contraste entre a cor da carteirinha e o texto branco, pela fórmula
/// da WCAG 2.1. Mesma regra da API (`api/src/organizacao/contraste.ts`).
abstract final class Contraste {
  /// Mínimo para texto normal ficar legível.
  static const minimo = 4.5;

  /// Contraste de [cor] com o branco, de 1 a 21.
  static double comBranco(Color cor) => 1.05 / (_luminancia(cor) + 0.05);

  static bool legivelComBranco(Color cor) => comBranco(cor) >= minimo;

  /// Contraste entre duas cores quaisquer, de 1 a 21.
  static double entre(Color a, Color b) {
    final (la, lb) = (_luminancia(a), _luminancia(b));
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
  }

  /// [cor] escurecida só o necessário para o texto branco ficar legível em cima.
  static Color escurecerParaBranco(Color cor, {double inicio = 0.35}) {
    for (var f = inicio; f < 0.95; f += 0.05) {
      final escura = Color.lerp(cor, const Color(0xFF000000), f)!;
      if (legivelComBranco(escura)) return escura;
    }
    return Color.lerp(cor, const Color(0xFF000000), 0.95)!;
  }

  static double _luminancia(Color cor) {
    double canal(double c) => c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * canal(cor.r) + 0.7152 * canal(cor.g) + 0.0722 * canal(cor.b);
  }

  /// "#2B2FB8" → Color; `null` se o texto não for uma cor válida.
  static Color? lerHex(String texto) {
    final hex = texto.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Color → "#2B2FB8"
  static String paraHex(Color cor) {
    String canal(double c) => (c * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${canal(cor.r)}${canal(cor.g)}${canal(cor.b)}'.toUpperCase();
  }
}
