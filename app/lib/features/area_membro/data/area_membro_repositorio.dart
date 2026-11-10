import 'dart:convert';
import 'dart:typed_data';

import '../../../core/api/cliente_api.dart';
import '../../../core/formatacao/datas.dart';
import '../../beneficios/domain/beneficio.dart';
import '../../membros/domain/membro.dart';
import '../../unidades/domain/unidade_evento.dart';
import '../domain/carteirinha_membro.dart';

class AreaMembroRepositorioApi implements AreaMembroRepositorio {
  AreaMembroRepositorioApi(this._api);

  final ClienteApi _api;

  @override
  Future<CadastroMembro> cadastro() async =>
      CadastroMembro.deJson(await _api.get('/membro/cadastro') as Map<String, dynamic>);

  @override
  Future<CadastroMembro> completarCadastro(DadosCadastroMembro dados) async =>
      CadastroMembro.deJson(await _api.put('/membro/cadastro', dados.paraJson()) as Map<String, dynamic>);

  @override
  Future<CarteirinhaMembro> carteirinha() async =>
      CarteirinhaMembro.deJson(await _api.get('/membro/carteirinha') as Map<String, dynamic>);

  @override
  Future<CarteirinhaMembro> salvarFoto(Uint8List? foto, {String? tipo}) async => CarteirinhaMembro.deJson(
    await _api.put('/membro/foto', {
          'foto': foto == null ? null : base64Encode(foto),
          'fotoTipo': foto == null ? null : tipo,
        })
        as Map<String, dynamic>,
  );

  @override
  Future<List<Beneficio>> beneficios() async => [
    for (final b in await _api.get('/membro/beneficios') as List) Beneficio.deJson(b as Map<String, dynamic>),
  ];

  @override
  Future<List<UnidadeEvento>> locais() async => [
    for (final u in await _api.get('/membro/locais') as List) UnidadeEvento.deJson(u as Map<String, dynamic>),
  ];
}

/// Área do membro em memória, para os testes rodarem sem a API.
class AreaMembroRepositorioMock implements AreaMembroRepositorio {
  AreaMembroRepositorioMock({
    this.status = StatusCarteirinha.ativa,
    this.diasParaVencer = 20,
    this.cadastroPendente = false,
  });

  /// Simula o primeiro acesso, com o cadastro ainda por preencher.
  bool cadastroPendente;

  /// O último cadastro enviado pelo formulário.
  DadosCadastroMembro? cadastroEnviado;

  /// Situação simulada, para testar bloqueio e vencimento.
  StatusCarteirinha status;
  int diasParaVencer;

  /// Quantas vezes a carteirinha foi buscada.
  int buscas = 0;

  /// Simula a falta de conexão nas próximas buscas.
  bool semConexao = false;

  Uint8List? foto;

  @override
  Future<CadastroMembro> cadastro() async {
    if (semConexao) throw Exception('sem conexão');
    final d = cadastroEnviado;
    return CadastroMembro(
      nome: d?.nome ?? 'Marina Membro',
      email: 'membro@membropass.dev',
      telefone: d?.telefone ?? '(54) 99999-0001',
      dataNascimento: d?.dataNascimento,
      endereco: d?.endereco,
      foto: foto,
      confirmadoEm: cadastroPendente ? null : DateTime(2026, 11, 1),
    );
  }

  @override
  Future<CadastroMembro> completarCadastro(DadosCadastroMembro dados) async {
    if (dados.foto != null) foto = dados.foto;
    if (foto == null) throw ErroApi(400, 'Escolha uma foto para a carteirinha.');
    cadastroEnviado = dados;
    cadastroPendente = false;
    return cadastro();
  }

  @override
  Future<CarteirinhaMembro> carteirinha() async {
    buscas++;
    if (semConexao) throw Exception('sem conexão');
    final hoje = Datas.hoje();
    final ativa = status == StatusCarteirinha.ativa;
    return CarteirinhaMembro(
      nomeMembro: cadastroEnviado?.nome ?? 'Marina Membro',
      foto: foto,
      planoNome: 'Mensal',
      planoCor: '#3A9FE0',
      numero: '38F29DBA',
      status: status,
      dataEmissao: hoje.subtract(const Duration(days: 10)),
      dataVencimento: hoje.add(Duration(days: diasParaVencer)),
      qrCodigo: ativa ? 'qr-de-teste' : null,
    );
  }

  @override
  Future<CarteirinhaMembro> salvarFoto(Uint8List? foto, {String? tipo}) async {
    this.foto = foto;
    return carteirinha();
  }

  @override
  Future<List<Beneficio>> beneficios() async => const [
    Beneficio(
      id: 'b1',
      nome: 'Desconto na farmácia',
      descricao: 'Apresente a carteirinha no caixa.',
      parceiro: 'Farmácia Central',
      tipoDesconto: TipoDesconto.percentual,
      valorDesconto: 15,
      planoIds: [],
    ),
  ];

  @override
  Future<List<UnidadeEvento>> locais() async => const [
    UnidadeEvento(
      id: 'e1',
      nome: 'Sede Central',
      tipo: TipoLocal.unidade,
      localizacao: 'Rua das Flores, 100 - Centro',
      planoIds: [],
    ),
  ];
}
