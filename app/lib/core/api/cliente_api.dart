import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente HTTP da API NestJS (`api/`), compartilhado pelos repositórios.
/// Guarda o token do login e o envia nas chamadas seguintes.
class ClienteApi {
  ClienteApi({String? urlBase, http.Client? cliente})
    : _urlBase = urlBase ?? urlPadrao,
      _cliente = cliente ?? http.Client();

  /// Troque com `flutter run --dart-define=API_URL=...`. O padrão aponta
  /// para o computador visto de dentro do emulador Android (10.0.2.2).
  static const urlPadrao = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');

  final String _urlBase;
  final http.Client _cliente;

  /// Token JWT do usuário logado; `null` depois de sair.
  String? token;

  /// A API gratuita online "dorme" sem uso e leva perto de 1 minuto para
  /// acordar: o primeiro pedido precisa esperar mais que o normal.
  static const tempoLimite = Duration(seconds: 70);

  /// Chamado ao abrir o app: começa a acordar a API enquanto a pessoa ainda
  /// digita o login. Erros são ignorados (é só um aviso).
  void acordar() {
    _cliente.get(Uri.parse('$_urlBase/saude')).timeout(tempoLimite).then((_) {}, onError: (_) {});
  }

  Future<dynamic> get(String caminho) => _enviar('GET', caminho);
  Future<dynamic> post(String caminho, Object corpo) => _enviar('POST', caminho, corpo);
  Future<dynamic> put(String caminho, Object corpo) => _enviar('PUT', caminho, corpo);
  Future<dynamic> patch(String caminho, Object corpo) => _enviar('PATCH', caminho, corpo);
  Future<dynamic> delete(String caminho) => _enviar('DELETE', caminho);

  /// Devolve o JSON da resposta (ou `null` se vier vazia).
  /// Lança [ErroApi] quando a API responde com erro.
  Future<dynamic> _enviar(String metodo, String caminho, [Object? corpo]) async {
    final requisicao = http.Request(metodo, Uri.parse('$_urlBase$caminho'))
      ..headers['Content-Type'] = 'application/json';
    if (token != null) requisicao.headers['Authorization'] = 'Bearer $token';
    if (corpo != null) requisicao.body = jsonEncode(corpo);

    final resposta = await http.Response.fromStream(await _cliente.send(requisicao).timeout(tempoLimite));
    final json = resposta.body.isEmpty ? null : jsonDecode(resposta.body);

    if (resposta.statusCode >= 400) {
      throw ErroApi(resposta.statusCode, _mensagemDe(json));
    }
    return json;
  }

  /// O NestJS manda `message` como texto ou, na validação, como lista.
  static String _mensagemDe(dynamic json) {
    final mensagem = json is Map ? json['message'] : null;
    if (mensagem is List && mensagem.isNotEmpty) return mensagem.first.toString();
    if (mensagem is String) return mensagem;
    return 'Não foi possível concluir. Tente novamente.';
  }
}

class ErroApi implements Exception {
  const ErroApi(this.status, this.mensagem);

  final int status;

  /// Mensagem da API, já pronta para mostrar ao usuário.
  final String mensagem;

  @override
  String toString() => 'ErroApi($status): $mensagem';
}
