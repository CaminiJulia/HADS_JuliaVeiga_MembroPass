/// Datas no formato brasileiro e no formato da API (AAAA-MM-DD).
abstract final class Datas {
  /// 2026-03-05 → "05/03/2026"
  static String formatar(DateTime data) =>
      '${_dois(data.day)}/${_dois(data.month)}/${data.year}';

  /// 2026-03-05 → "2026-03-05", como a API espera.
  static String paraApi(DateTime data) => '${data.year}-${_dois(data.month)}-${_dois(data.day)}';

  /// "2026-03-05" → DateTime(2026, 3, 5); `null` continua `null`.
  static DateTime? daApi(String? texto) => texto == null ? null : DateTime.parse(texto);

  /// Hoje, sem as horas, para comparar só o dia.
  static DateTime hoje([DateTime Function() agora = DateTime.now]) {
    final h = agora();
    return DateTime(h.year, h.month, h.day);
  }

  static String _dois(int n) => n.toString().padLeft(2, '0');
}
