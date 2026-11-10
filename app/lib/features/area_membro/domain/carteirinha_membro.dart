import 'dart:convert';
import 'dart:typed_data';

import '../../../core/formatacao/datas.dart';
import '../../beneficios/domain/beneficio.dart';
import '../../membros/domain/membro.dart';
import '../../unidades/domain/unidade_evento.dart';

/// Como a carteirinha está hoje, do ponto de vista do membro.
enum SituacaoCarteirinha {
  emDia('Em dia'),
  venceEmBreve('Vence em breve'),
  vencida('Vencida'),
  bloqueada('Bloqueada'),
  invalidada('Inativa');

  const SituacaoCarteirinha(this.rotulo);

  final String rotulo;

  /// Bloqueada ou invalidada pela administração: sem QR Code.
  bool get semQr => this == bloqueada || this == invalidada;
}

/// Carteirinha do membro logado (RF05), com o QR Code do check-in.
class CarteirinhaMembro {
  const CarteirinhaMembro({
    required this.nomeMembro,
    required this.planoNome,
    required this.numero,
    required this.status,
    required this.dataEmissao,
    required this.dataVencimento,
    this.planoCor,
    this.foto,
    this.qrCodigo,
  });

  factory CarteirinhaMembro.deJson(Map<String, dynamic> json) {
    final membro = json['membro'] as Map<String, dynamic>;
    final plano = json['plano'] as Map<String, dynamic>;
    final carteirinha = json['carteirinha'] as Map<String, dynamic>;
    final qr = json['qr'] as Map<String, dynamic>?;
    return CarteirinhaMembro(
      nomeMembro: membro['nome'] as String,
      foto: membro['foto'] == null ? null : base64Decode(membro['foto'] as String),
      planoNome: plano['nome'] as String,
      planoCor: plano['cor'] as String?,
      numero: carteirinha['numero'] as String,
      status: StatusCarteirinha.values.byName((carteirinha['status'] as String).toLowerCase()),
      dataEmissao: Datas.daApi(carteirinha['dataEmissao'] as String)!,
      dataVencimento: Datas.daApi(carteirinha['dataVencimento'] as String)!,
      qrCodigo: qr?['codigo'] as String?,
    );
  }

  final String nomeMembro;

  /// Foto escolhida pelo próprio membro; aparece na carteirinha.
  final Uint8List? foto;
  final String planoNome;
  final String? planoCor;

  /// Número curto, para conferência visual pelo operador.
  final String numero;
  final StatusCarteirinha status;
  final DateTime dataEmissao;
  final DateTime dataVencimento;

  /// Código fixo assinado pela API; `null` quando a carteirinha está bloqueada.
  final String? qrCodigo;

  /// Dias até o vencimento (negativo se já venceu).
  int diasParaVencer(DateTime hoje) => dataVencimento.difference(hoje).inDays;

  SituacaoCarteirinha situacao(DateTime hoje) {
    if (status == StatusCarteirinha.invalidada) return SituacaoCarteirinha.invalidada;
    if (status == StatusCarteirinha.bloqueada) return SituacaoCarteirinha.bloqueada;
    final dias = diasParaVencer(hoje);
    if (dias < 0) return SituacaoCarteirinha.vencida;
    if (dias <= Membro.diasAviso) return SituacaoCarteirinha.venceEmBreve;
    return SituacaoCarteirinha.emDia;
  }
}

/// Endereço informado pelo membro no primeiro acesso.
class EnderecoMembro {
  const EnderecoMembro({
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.uf,
    this.complemento,
  });

  /// Endereço vazio, se ainda não foi preenchido.
  static EnderecoMembro? deJson(Map<String, dynamic>? json) {
    if (json == null || json['cep'] == null) return null;
    return EnderecoMembro(
      cep: json['cep'] as String,
      logradouro: json['logradouro'] as String,
      numero: json['numero'] as String,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String,
      cidade: json['cidade'] as String,
      uf: json['uf'] as String,
    );
  }

  final String cep;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String uf;

  Map<String, dynamic> paraJson() => {
    'cep': cep,
    'logradouro': logradouro,
    'numero': numero,
    'complemento': complemento,
    'bairro': bairro,
    'cidade': cidade,
    'uf': uf,
  };
}

/// Dados pessoais do membro, preenchidos e confirmados por ele no primeiro acesso.
class CadastroMembro {
  const CadastroMembro({
    required this.nome,
    required this.email,
    this.telefone,
    this.dataNascimento,
    this.endereco,
    this.foto,
    this.confirmadoEm,
  });

  factory CadastroMembro.deJson(Map<String, dynamic> json) => CadastroMembro(
    nome: json['nome'] as String,
    email: json['email'] as String,
    telefone: json['telefone'] as String?,
    dataNascimento: Datas.daApi(json['dataNascimento'] as String?),
    endereco: EnderecoMembro.deJson(json['endereco'] as Map<String, dynamic>?),
    foto: json['foto'] == null ? null : base64Decode(json['foto'] as String),
    confirmadoEm: json['confirmadoEm'] == null ? null : DateTime.parse(json['confirmadoEm'] as String),
  );

  final String nome;
  final String email;
  final String? telefone;
  final DateTime? dataNascimento;
  final EnderecoMembro? endereco;
  final Uint8List? foto;

  /// Quando o membro declarou que os dados são verdadeiros; `null` no primeiro acesso.
  final DateTime? confirmadoEm;

  bool get pendente => confirmadoEm == null;
}

/// O que o membro envia ao concluir o cadastro. [foto] `null` mantém a atual.
class DadosCadastroMembro {
  const DadosCadastroMembro({
    required this.nome,
    required this.telefone,
    required this.dataNascimento,
    required this.endereco,
    this.foto,
    this.fotoTipo,
  });

  final String nome;
  final String telefone;
  final DateTime dataNascimento;
  final EnderecoMembro endereco;
  final Uint8List? foto;
  final String? fotoTipo;

  Map<String, dynamic> paraJson() => {
    'nome': nome,
    'telefone': telefone,
    'dataNascimento': Datas.paraApi(dataNascimento),
    ...endereco.paraJson(),
    if (foto != null) 'foto': base64Encode(foto!),
    if (foto != null) 'fotoTipo': fotoTipo,
    // O formulário só envia depois de o membro marcar a declaração.
    'declaracao': true,
  };
}

/// O que o membro logado vê: a própria carteirinha, benefícios e locais.
abstract interface class AreaMembroRepositorio {
  /// Dados pessoais e se o primeiro acesso já foi concluído.
  Future<CadastroMembro> cadastro();

  /// Grava os dados do primeiro acesso, com a declaração de veracidade.
  Future<CadastroMembro> completarCadastro(DadosCadastroMembro dados);

  Future<CarteirinhaMembro> carteirinha();

  /// Troca (ou remove, com `null`) a foto da carteirinha.
  Future<CarteirinhaMembro> salvarFoto(Uint8List? foto, {String? tipo});

  /// Benefícios vigentes do plano do membro (RF09).
  Future<List<Beneficio>> beneficios();

  /// Unidades e eventos (não encerrados) onde o plano é aceito.
  Future<List<UnidadeEvento>> locais();
}
