import '../../../core/api/cliente_api.dart';
import '../domain/unidade_evento.dart';

/// Unidades e eventos em memória, para os testes rodarem sem a API.
/// Os ids de plano batem com os do `PlanosRepositorioMock`.
class UnidadesRepositorioMock implements UnidadesRepositorio {
  final _locais = <UnidadeEvento>[
    const UnidadeEvento(
      id: 'u1',
      nome: 'Sede Central',
      tipo: TipoLocal.unidade,
      localizacao: 'Rua das Flores, 100',
      planoIds: ['p1', 'p2'],
    ),
  ];
  var _proximoId = 2;

  @override
  Future<List<UnidadeEvento>> listar() async => List.of(_locais);

  @override
  Future<UnidadeEvento> criar(DadosUnidadeEvento dados) async {
    final local = _deDados('u${_proximoId++}', dados);
    _locais.add(local);
    return local;
  }

  @override
  Future<UnidadeEvento> editar(String id, DadosUnidadeEvento dados) async =>
      _locais[_indice(id)] = _deDados(id, dados, anterior: _locais[_indice(id)]);

  @override
  Future<void> excluir(String id) async => _locais.removeAt(_indice(id));

  int _indice(String id) {
    final i = _locais.indexWhere((l) => l.id == id);
    if (i < 0) throw const ErroApi(404, 'Unidade ou evento não encontrado.');
    return i;
  }

  static UnidadeEvento _deDados(String id, DadosUnidadeEvento d, {UnidadeEvento? anterior}) {
    if (d.tipo == TipoLocal.evento && (d.dataInicio == null || d.dataFim == null)) {
      throw const ErroApi(400, 'Informe o início e o fim do evento.');
    }
    final evento = d.tipo == TipoLocal.evento;
    return UnidadeEvento(
      id: id,
      nome: d.nome,
      tipo: d.tipo,
      localizacao: d.localizacao,
      dataInicio: evento ? d.dataInicio : null,
      dataFim: evento ? d.dataFim : null,
      planoIds: d.planoIds,
      imagem: d.manterImagem ? anterior?.imagem : d.imagem,
      imagemTipo: d.manterImagem ? anterior?.imagemTipo : d.imagemTipo,
    );
  }
}
