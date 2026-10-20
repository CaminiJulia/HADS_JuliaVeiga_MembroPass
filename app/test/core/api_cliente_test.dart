import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:membropass/core/api_cliente.dart';

void main() {
  group('ApiCliente', () {
    test('envia o token no cabeçalho e devolve o JSON da resposta', () async {
      late http.Request recebida;
      final api = ApiCliente(
        baseUrl: 'http://api/api',
        cliente: MockClient((requisicao) async {
          recebida = requisicao;
          return http.Response(jsonEncode({'ok': true}), 200);
        }),
      );

      final resposta = await api.get('/auth/eu', token: 'abc');

      expect(recebida.url.toString(), 'http://api/api/auth/eu');
      expect(recebida.headers['Authorization'], 'Bearer abc');
      expect(resposta, {'ok': true});
    });

    test('transforma o erro da API em ApiExcecao com a mensagem recebida', () async {
      final api = ApiCliente(
        baseUrl: 'http://api',
        cliente: MockClient((_) async =>
            http.Response(jsonEncode({'message': 'E-mail ou senha inválidos.'}), 401)),
      );

      expect(
        api.post('/auth/login', {}),
        throwsA(isA<ApiExcecao>()
            .having((e) => e.status, 'status', 401)
            .having((e) => e.mensagem, 'mensagem', 'E-mail ou senha inválidos.')),
      );
    });

    test('junta as mensagens dos erros de validação', () async {
      final api = ApiCliente(
        baseUrl: 'http://api',
        cliente: MockClient((_) async =>
            http.Response(jsonEncode({'message': ['Informe um e-mail válido.', 'Informe a senha.']}), 400)),
      );

      expect(
        api.post('/auth/login', {}),
        throwsA(isA<ApiExcecao>()
            .having((e) => e.mensagem, 'mensagem', 'Informe um e-mail válido.\nInforme a senha.')),
      );
    });

    test('avisa quando não consegue conectar ao servidor', () async {
      final api = ApiCliente(
        baseUrl: 'http://api',
        cliente: MockClient((_) async => throw http.ClientException('sem rede')),
      );

      expect(api.get('/saude'), throwsA(isA<ApiExcecao>().having((e) => e.status, 'status', 0)));
    });
  });
}
