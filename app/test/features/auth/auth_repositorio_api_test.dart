import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:membropass/core/api/cliente_api.dart';
import 'package:membropass/features/auth/data/auth_repositorio_api.dart';
import 'package:membropass/features/auth/domain/auth_repositorio.dart';
import 'package:membropass/features/auth/domain/papel.dart';

void main() {
  late ClienteApi api;

  AuthRepositorioApi repositorioRespondendo(int status, [Object? corpo]) {
    final cliente = MockClient(
      (_) async => http.Response(corpo == null ? '' : jsonEncode(corpo), status),
    );
    api = ClienteApi(urlBase: 'http://api', cliente: cliente);
    return AuthRepositorioApi(api);
  }

  test('converte a resposta do login em Usuario e guarda o token', () async {
    final repositorio = repositorioRespondendo(200, {
      'token': 'abc',
      'usuario': {
        'id': '1',
        'nome': 'Otávio Operador',
        'email': 'operador@membropass.dev',
        'papel': 'operador',
        'organizacaoId': 'org',
        'organizacaoNome': 'Clube Exemplo',
      },
    });

    final usuario = await repositorio.entrar(email: 'operador@membropass.dev', senha: 'x');

    expect(usuario.papel, Papel.operador);
    expect(usuario.organizacaoNome, 'Clube Exemplo');
    expect(api.token, 'abc');

    repositorio.sair();
    expect(api.token, isNull);
  });

  test('401 vira CredenciaisInvalidasException', () {
    final repositorio = repositorioRespondendo(401, {'message': 'E-mail ou senha incorretos.'});

    expect(
      repositorio.entrar(email: 'a@b.com', senha: 'x'),
      throwsA(isA<CredenciaisInvalidasException>()),
    );
  });

  test('429 traz a mensagem de bloqueio da API', () {
    final repositorio = repositorioRespondendo(429, {'message': 'Muitas tentativas.'});

    expect(
      repositorio.entrar(email: 'a@b.com', senha: 'x'),
      throwsA(isA<TentativasEsgotadasException>()
          .having((e) => e.mensagem, 'mensagem', 'Muitas tentativas.')),
    );
  });

  test('envia o token nas chamadas seguintes', () async {
    String? autorizacao;
    api = ClienteApi(
      urlBase: 'http://api',
      cliente: MockClient((requisicao) async {
        autorizacao = requisicao.headers['Authorization'];
        return http.Response('[]', 200);
      }),
    )..token = 'abc';

    await api.get('/planos');

    expect(autorizacao, 'Bearer abc');
  });
}
