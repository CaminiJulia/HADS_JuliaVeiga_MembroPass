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

/// O que o membro logado vê: a própria carteirinha, benefícios e locais.
abstract interface class AreaMembroRepositorio {
  Future<CarteirinhaMembro> carteirinha();

  /// Troca (ou remove, com `null`) a foto da carteirinha.
  Future<CarteirinhaMembro> salvarFoto(Uint8List? foto, {String? tipo});

  /// Benefícios vigentes do plano do membro (RF09).
  Future<List<Beneficio>> beneficios();

  /// Unidades e eventos (não encerrados) onde o plano é aceito.
  Future<List<UnidadeEvento>> locais();
}
