import '../../../core/api/cliente_api.dart';
import '../domain/organizacao.dart';

class OrganizacaoRepositorioApi implements OrganizacaoRepositorio {
  OrganizacaoRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<Organizacao> buscar() async => Organizacao.deJson(await _api.get('/organizacao') as Map<String, dynamic>);

  @override
  Future<Organizacao> salvarIdentidade(DadosIdentidade dados) async =>
      Organizacao.deJson(await _api.put('/organizacao/identidade', dados.paraJson()) as Map<String, dynamic>);
}

/// Organização em memória, para os testes rodarem sem a API.
class OrganizacaoRepositorioMock implements OrganizacaoRepositorio {
  var _organizacao = const Organizacao(id: 'org-1', nome: 'Clube Exemplo');

  @override
  Future<Organizacao> buscar() async => _organizacao;

  @override
  Future<Organizacao> salvarIdentidade(DadosIdentidade dados) async {
    final atual = _organizacao;
    return _organizacao = Organizacao(
      id: atual.id,
      nome: atual.nome,
      corPrincipal: dados.corPrincipal,
      logo: dados.manterLogo ? atual.logo : dados.logo,
      logoTipo: dados.manterLogo ? atual.logoTipo : dados.logoTipo,
    );
  }
}
