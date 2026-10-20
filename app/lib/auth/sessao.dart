import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../core/api_cliente.dart';
import 'auth_repositorio.dart';
import 'usuario.dart';

final apiClienteProvider = Provider<ApiCliente>((ref) => ApiCliente(baseUrl: apiUrl));

final authRepositorioProvider =
    Provider<AuthRepositorio>((ref) => AuthRepositorio(ref.watch(apiClienteProvider)));

final armazenamentoTokenProvider = Provider<ArmazenamentoToken>((ref) => ArmazenamentoTokenSeguro());

// Usuário logado, ou null quando ninguém entrou. A tela inicial do app depende
// só deste estado: cada papel abre a sua área (RF02).
final sessaoProvider = AsyncNotifierProvider<SessaoController, Usuario?>(SessaoController.new);

class SessaoController extends AsyncNotifier<Usuario?> {
  String? _token;

  String? get token => _token;

  AuthRepositorio get _repositorio => ref.read(authRepositorioProvider);
  ArmazenamentoToken get _armazenamento => ref.read(armazenamentoTokenProvider);

  // Ao abrir o app, restaura a sessão salva, se o token ainda for válido.
  @override
  Future<Usuario?> build() async {
    final salvo = await _armazenamento.ler();
    if (salvo == null) return null;
    try {
      final usuario = await _repositorio.perfil(salvo);
      _token = salvo;
      return usuario;
    } on ApiExcecao catch (erro) {
      // Token expirado ou cadastro desativado: volta para o login.
      if (erro.status == 401 || erro.status == 403) await _armazenamento.apagar();
      return null;
    }
  }

  // Lança ApiExcecao em caso de erro, para a tela de login mostrar a mensagem.
  Future<void> entrar(String email, String senha) async {
    final sessao = await _repositorio.entrar(email, senha);
    await _armazenamento.salvar(sessao.token);
    _token = sessao.token;
    state = AsyncData(sessao.usuario);
  }

  Future<void> sair() async {
    await _armazenamento.apagar();
    _token = null;
    state = const AsyncData(null);
  }
}
