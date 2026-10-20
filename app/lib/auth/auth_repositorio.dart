import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_cliente.dart';
import 'usuario.dart';

class Sessao {
  const Sessao({required this.token, required this.usuario});

  final String token;
  final Usuario usuario;
}

// Comunicação com a API de autenticação (RF01).
class AuthRepositorio {
  AuthRepositorio(this._api);

  final ApiCliente _api;

  Future<Sessao> entrar(String email, String senha) async {
    final json = await _api.post('/auth/login', {'email': email, 'senha': senha});
    return Sessao(
      token: json['accessToken'] as String,
      usuario: Usuario.deJson(json['usuario'] as Map<String, dynamic>),
    );
  }

  Future<Usuario> perfil(String token) async =>
      Usuario.deJson(await _api.get('/auth/eu', token: token));
}

// Guarda o token entre aberturas do app. No celular, o flutter_secure_storage
// usa o Keystore (Android) e o Keychain (iOS).
abstract class ArmazenamentoToken {
  Future<String?> ler();
  Future<void> salvar(String token);
  Future<void> apagar();
}

class ArmazenamentoTokenSeguro implements ArmazenamentoToken {
  static const _chave = 'membropass_token';
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> ler() => _storage.read(key: _chave);

  @override
  Future<void> salvar(String token) => _storage.write(key: _chave, value: token);

  @override
  Future<void> apagar() => _storage.delete(key: _chave);
}
