import '../../../core/api/cliente_api.dart';
import '../domain/perfil.dart';

class PerfilRepositorioApi implements PerfilRepositorio {
  PerfilRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<Perfil> buscar() async => Perfil.deJson(await _api.get('/perfil') as Map<String, dynamic>);

  @override
  Future<Perfil> salvar(DadosPerfil dados) async =>
      Perfil.deJson(await _api.put('/perfil', dados.paraJson()) as Map<String, dynamic>);

  @override
  Future<void> trocarSenha({required String senhaAtual, required String novaSenha}) async {
    await _api.put('/perfil/senha', {'senhaAtual': senhaAtual, 'novaSenha': novaSenha});
  }
}

/// Perfil em memória, para os testes rodarem sem a API.
class PerfilRepositorioMock implements PerfilRepositorio {
  var _perfil = const Perfil(
    id: 'adm-1',
    nome: 'Ana Administradora',
    email: 'admin@membropass.dev',
    organizacaoNome: 'Clube Exemplo',
  );
  var _senha = 'Senha@123';

  @override
  Future<Perfil> buscar() async => _perfil;

  @override
  Future<Perfil> salvar(DadosPerfil dados) async {
    final atual = _perfil;
    return _perfil = Perfil(
      id: atual.id,
      nome: dados.nome,
      email: atual.email,
      organizacaoNome: atual.organizacaoNome,
      telefone: dados.telefone,
      cargo: dados.cargo,
      foto: dados.manterFoto ? atual.foto : dados.foto,
      fotoTipo: dados.manterFoto ? atual.fotoTipo : dados.fotoTipo,
    );
  }

  @override
  Future<void> trocarSenha({required String senhaAtual, required String novaSenha}) async {
    if (senhaAtual != _senha) throw const ErroApi(400, 'A senha atual está incorreta.');
    _senha = novaSenha;
  }
}
