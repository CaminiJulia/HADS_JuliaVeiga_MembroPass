import '../../../core/api/cliente_api.dart';
import '../domain/plano.dart';
import '../domain/planos_repositorio.dart';

/// Planos em memória, para os testes rodarem sem a API.
class PlanosRepositorioMock implements PlanosRepositorio {
  final _planos = <Plano>[
    const Plano(id: 'p1', nome: 'Mensal', valorReferencia: 89.9, duracaoDias: 30, ativo: true, cor: '#3A9FE0'),
    const Plano(id: 'p2', nome: 'Anual', valorReferencia: 899, duracaoDias: 365, ativo: true),
  ];
  var _proximoId = 3;

  @override
  Future<List<Plano>> listar() async => List.of(_planos);

  @override
  Future<Plano> criar(DadosPlano dados) async {
    _exigirNomeUnico(dados.nome);
    final plano = Plano(
      id: 'p${_proximoId++}',
      nome: dados.nome,
      valorReferencia: dados.valorReferencia,
      duracaoDias: dados.duracaoDias,
      ativo: true,
      cor: dados.cor,
    );
    _planos.add(plano);
    return plano;
  }

  @override
  Future<Plano> editar(String id, DadosPlano dados) async {
    _exigirNomeUnico(dados.nome, ignorarId: id);
    return _substituir(
      id,
      (p) => p.copyWith(
        nome: dados.nome,
        valorReferencia: dados.valorReferencia,
        duracaoDias: dados.duracaoDias,
        cor: () => dados.cor,
      ),
    );
  }

  @override
  Future<Plano> alterarAtivo(String id, {required bool ativo}) async =>
      _substituir(id, (p) => p.copyWith(ativo: ativo));

  Plano _substituir(String id, Plano Function(Plano) alterar) {
    final i = _planos.indexWhere((p) => p.id == id);
    if (i < 0) throw const ErroApi(404, 'Plano não encontrado.');
    return _planos[i] = alterar(_planos[i]);
  }

  void _exigirNomeUnico(String nome, {String? ignorarId}) {
    final repetido = _planos.any((p) => p.id != ignorarId && p.nome.toLowerCase() == nome.trim().toLowerCase());
    if (repetido) throw const ErroApi(409, 'Já existe um plano com esse nome.');
  }
}
