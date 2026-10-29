import 'package:flutter/foundation.dart';

import '../domain/auth_repositorio.dart';
import '../domain/limitador_tentativas.dart';
import '../domain/usuario.dart';

class LoginController extends ChangeNotifier {
  LoginController(this._repositorio, this._limitador);

  final AuthRepositorio _repositorio;
  final LimitadorTentativas _limitador;

  bool _carregando = false;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  /// Devolve o usuário autenticado, ou `null` quando o login falha
  /// (nesse caso [erro] traz a mensagem a exibir).
  Future<Usuario?> entrar(String email, String senha) async {
    final bloqueio = _limitador.tempoRestante(email);
    if (bloqueio != null) {
      _definirErro(_mensagemBloqueio(bloqueio));
      return null;
    }

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final usuario = await _repositorio.entrar(email: email, senha: senha);
      _limitador.limpar(email);
      return usuario;
    } on CredenciaisInvalidasException {
      _limitador.registrarFalha(email);
      final novoBloqueio = _limitador.tempoRestante(email);
      // Mensagem genérica: não revela se o erro foi no e-mail ou na senha.
      _erro = novoBloqueio == null
          ? 'E-mail ou senha incorretos.'
          : _mensagemBloqueio(novoBloqueio);
      return null;
    } catch (_) {
      _erro = 'Não foi possível entrar agora. Verifique sua conexão e tente novamente.';
      return null;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void limparErro() {
    if (_erro == null) return;
    _definirErro(null);
  }

  void _definirErro(String? mensagem) {
    _erro = mensagem;
    notifyListeners();
  }

  static String _mensagemBloqueio(Duration restante) {
    final segundos = restante.inSeconds + 1;
    final tempo = segundos >= 60
        ? '${(segundos / 60).ceil()} min'
        : '$segundos s';
    return 'Muitas tentativas sem sucesso. Tente novamente em $tempo.';
  }
}
