/// Datas no formato brasileiro e no formato da API (AAAA-MM-DD).
abstract final class Datas {
  /// 2026-03-05 → "05/03/2026"
  static String formatar(DateTime data) => '${_dois(data.day)}/${_dois(data.month)}/${data.year}';

  /// 2026-03-05 → "2026-03-05", como a API espera.
  static String paraApi(DateTime data) => '${data.year}-${_dois(data.month)}-${_dois(data.day)}';

  /// "2026-03-05" → DateTime(2026, 3, 5); `null` continua `null`.
  static DateTime? daApi(String? texto) => texto == null ? null : DateTime.parse(texto);

  /// Hoje, sem as horas, para comparar só o dia.
  static DateTime hoje([DateTime Function() agora = DateTime.now]) {
    final h = agora();
    return DateTime(h.year, h.month, h.day);
  }

  static const _meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  /// 3 → "MAR"
  static String mesAbreviado(int mes) => _meses[mes - 1].substring(0, 3).toUpperCase();

  /// Período por extenso: "23 de novembro de 2026", "23 a 25 de novembro de 2026",
  /// "30 de novembro a 2 de dezembro de 2026" ou, em anos diferentes, as duas datas completas.
  static String periodoPorExtenso(DateTime inicio, DateTime fim) {
    String dia(DateTime d) => '${d.day} de ${_meses[d.month - 1]}';
    if (inicio == fim) return '${dia(inicio)} de ${inicio.year}';
    if (inicio.year != fim.year) return '${dia(inicio)} de ${inicio.year} a ${dia(fim)} de ${fim.year}';
    if (inicio.month != fim.month) return '${dia(inicio)} a ${dia(fim)} de ${fim.year}';
    return '${inicio.day} a ${dia(fim)} de ${fim.year}';
  }

  static String _dois(int n) => n.toString().padLeft(2, '0');
}
