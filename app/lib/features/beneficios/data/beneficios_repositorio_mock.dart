import '../../../core/api/cliente_api.dart';
import '../domain/beneficio.dart';
import '../domain/beneficios_repositorio.dart';

/// Benefícios em memória, para os testes rodarem sem a API.
/// Os ids de plano batem com os do `PlanosRepositorioMock`.
class BeneficiosRepositorioMock implements BeneficiosRepositorio {
  final _beneficios = <Beneficio>[
    const Beneficio(
      id: 'b1',
      nome: 'Desconto na farmácia',
      parceiro: 'Farmácia Central',
      tipoDesconto: TipoDesconto.percentual,
      valorDesconto: 15,
      planoIds: ['p1', 'p2'],
    ),
  ];
  var _proximoId = 2;

  @override
  Future<List<Beneficio>> listar() async => List.of(_beneficios);

  @override
  Future<Beneficio> criar(DadosBeneficio dados) async {
    final beneficio = _deDados('b${_proximoId++}', dados);
    _beneficios.add(beneficio);
    return beneficio;
  }

  @override
  Future<Beneficio> editar(String id, DadosBeneficio dados) async {
    final i = _indice(id);
    return _beneficios[i] = _deDados(id, dados, anterior: _beneficios[i]);
  }

  @override
  Future<void> excluir(String id) async => _beneficios.removeAt(_indice(id));

  int _indice(String id) {
    final i = _beneficios.indexWhere((b) => b.id == id);
    if (i < 0) throw const ErroApi(404, 'Benefício não encontrado.');
    return i;
  }

  static Beneficio _deDados(String id, DadosBeneficio d, {Beneficio? anterior}) => Beneficio(
    id: id,
    nome: d.nome,
    descricao: d.descricao,
    parceiro: d.parceiro,
    tipoDesconto: d.tipoDesconto,
    valorDesconto: d.valorDesconto,
    vigInicio: d.vigInicio,
    vigFim: d.vigFim,
    planoIds: d.planoIds,
    logo: d.manterLogo ? anterior?.logo : d.logo,
    logoTipo: d.manterLogo ? anterior?.logoTipo : d.logoTipo,
  );
}
