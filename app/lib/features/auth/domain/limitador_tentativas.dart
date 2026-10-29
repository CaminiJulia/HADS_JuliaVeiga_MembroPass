/// Bloqueia temporariamente o login de um e-mail após várias tentativas
/// malsucedidas seguidas (RF01 — Segurança).
///
/// No app ele dá retorno imediato ao usuário; a regra definitiva também
/// será aplicada na API, que é quem garante a segurança de fato.
class LimitadorTentativas {
  LimitadorTentativas({
    this.maximoTentativas = 5,
    this.tempoBloqueio = const Duration(minutes: 1),
    DateTime Function()? relogio,
  }) : _agora = relogio ?? DateTime.now;

  final int maximoTentativas;
  final Duration tempoBloqueio;
  final DateTime Function() _agora;

  final _falhas = <String, int>{};
  final _bloqueadoAte = <String, DateTime>{};

  /// Tempo que falta para liberar o e-mail, ou `null` se não está bloqueado.
  Duration? tempoRestante(String email) {
    final chave = _chave(email);
    final ate = _bloqueadoAte[chave];
    if (ate == null) return null;

    final restante = ate.difference(_agora());
    if (restante > Duration.zero) return restante;

    _bloqueadoAte.remove(chave);
    _falhas.remove(chave);
    return null;
  }

  void registrarFalha(String email) {
    final chave = _chave(email);
    final falhas = (_falhas[chave] ?? 0) + 1;
    _falhas[chave] = falhas;
    if (falhas >= maximoTentativas) {
      _bloqueadoAte[chave] = _agora().add(tempoBloqueio);
    }
  }

  void limpar(String email) {
    final chave = _chave(email);
    _falhas.remove(chave);
    _bloqueadoAte.remove(chave);
  }

  String _chave(String email) => email.trim().toLowerCase();
}
