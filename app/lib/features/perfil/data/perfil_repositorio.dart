import '../../../core/api/cliente_api.dart';
import '../../auth/domain/papel.dart';
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
    final corpo =
        await _api.put('/auth/senha', {'senhaAtual': senhaAtual, 'novaSenha': novaSenha}) as Map<String, dynamic>;
    // As outras sessões caem; esta segue com o token novo.
    _api.token = corpo['token'] as String;
  }
}

/// Perfil em memória, para os testes rodarem sem a API.
/// Padrão: o administrador; [PerfilRepositorioMock.operador] para o operador.
class PerfilRepositorioMock implements PerfilRepositorio {
  PerfilRepositorioMock([Perfil? inicial])
    : _perfil =
          inicial ??
          const Perfil(
            id: 'adm-1',
            nome: 'Ana Administradora',
            email: 'admin@membropass.dev',
            organizacaoNome: 'Clube Exemplo',
          );

  PerfilRepositorioMock.operador()
    : this(
        const Perfil(
          id: 'op-1',
          nome: 'Otávio Operador',
          email: 'operador@membropass.dev',
          organizacaoNome: 'Clube Exemplo',
          papel: Papel.operador,
        ),
      );

  Perfil _perfil;
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
      papel: atual.papel,
      telefone: dados.telefone,
      cargo: atual.temCargo ? dados.cargo : null,
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
