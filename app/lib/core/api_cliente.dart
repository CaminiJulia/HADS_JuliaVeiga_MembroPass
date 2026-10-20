import 'dart:convert';

import 'package:http/http.dart' as http;

// Erro devolvido pela API, já com a mensagem pronta para mostrar ao usuário.
class ApiExcecao implements Exception {
  const ApiExcecao(this.status, this.mensagem);

  final int status;
  final String mensagem;

  // O NestJS devolve "message" como texto ou, nos erros de validação, como lista.
  factory ApiExcecao.daResposta(http.Response resposta) {
    String mensagem = 'Erro inesperado (${resposta.statusCode}). Tente novamente.';
    try {
      final corpo = jsonDecode(resposta.body);
      final recebida = corpo is Map<String, dynamic> ? corpo['message'] : null;
      if (recebida is String) mensagem = recebida;
      if (recebida is List && recebida.isNotEmpty) mensagem = recebida.join('\n');
    } on FormatException {
      // Corpo que não é JSON: mantém a mensagem genérica.
    }
    return ApiExcecao(resposta.statusCode, mensagem);
  }

  @override
  String toString() => mensagem;
}

class ApiCliente {
  ApiCliente({required this.baseUrl, http.Client? cliente}) : _http = cliente ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  Future<Map<String, dynamic>> get(String caminho, {String? token}) =>
      _enviar(() => _http.get(_uri(caminho), headers: _cabecalhos(token)));

  Future<Map<String, dynamic>> post(String caminho, Map<String, dynamic> corpo, {String? token}) =>
      _enviar(() => _http.post(_uri(caminho), headers: _cabecalhos(token), body: jsonEncode(corpo)));

  Uri _uri(String caminho) => Uri.parse('$baseUrl$caminho');

  Map<String, String> _cabecalhos(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _enviar(Future<http.Response> Function() requisicao) async {
    final http.Response resposta;
    try {
      resposta = await requisicao().timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ApiExcecao(0, 'Não foi possível conectar ao servidor. Verifique sua internet.');
    }
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ApiExcecao.daResposta(resposta);
    }
    return resposta.body.isEmpty ? {} : jsonDecode(resposta.body) as Map<String, dynamic>;
  }
}
