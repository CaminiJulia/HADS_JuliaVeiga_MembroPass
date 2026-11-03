import 'dart:convert';
import 'dart:typed_data';

import '../../../core/formatacao/datas.dart';
import '../../../core/formatacao/moeda.dart';

enum TipoDesconto { percentual, valor }

/// Benefício oferecido pela organização a alguns planos (RF08).
class Beneficio {
  const Beneficio({
    required this.id,
    required this.nome,
    required this.tipoDesconto,
    required this.valorDesconto,
    required this.planoIds,
    this.descricao,
    this.parceiro,
    this.vigInicio,
    this.vigFim,
    this.logo,
    this.logoTipo,
  });

  factory Beneficio.deJson(Map<String, dynamic> json) => Beneficio(
    id: json['id'] as String,
    nome: json['nome'] as String,
    descricao: json['descricao'] as String?,
    parceiro: json['parceiro'] as String?,
    tipoDesconto: json['tipoDesconto'] == 'PERCENTUAL' ? TipoDesconto.percentual : TipoDesconto.valor,
    valorDesconto: (json['valorDesconto'] as num).toDouble(),
    vigInicio: Datas.daApi(json['vigInicio'] as String?),
    vigFim: Datas.daApi(json['vigFim'] as String?),
    planoIds: [for (final id in json['planoIds'] as List) id as String],
    logo: json['logo'] == null ? null : base64Decode(json['logo'] as String),
    logoTipo: json['logoTipo'] as String?,
  );

  final String id;
  final String nome;
  final String? descricao;
  final String? parceiro;
  final TipoDesconto tipoDesconto;
  final double valorDesconto;

  /// Vigência opcional; sem datas, o benefício vale sempre.
  final DateTime? vigInicio;
  final DateTime? vigFim;

  final List<String> planoIds;

  /// Logo do parceiro (PNG ou JPEG), mostrado no cartão do benefício.
  final Uint8List? logo;
  final String? logoTipo;

  /// Iniciais do parceiro (ou do benefício) para quando não há logo: "Farmácia Central" → "FC".
  String get iniciais {
    final palavras = (parceiro ?? nome).trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (palavras.isEmpty) return '?';
    final primeira = palavras.first[0];
    return (palavras.length > 1 ? '$primeira${palavras[1][0]}' : primeira).toUpperCase();
  }

  /// Valor curto para o selo do cupom: "15%", "12,5%", "R\$ 50" ou "R\$ 12,50".
  String get valorCurto {
    if (tipoDesconto == TipoDesconto.percentual) return '${_semZeros(valorDesconto)}%';
    final inteiro = valorDesconto == valorDesconto.roundToDouble();
    return inteiro ? 'R\$ ${valorDesconto.toStringAsFixed(0)}' : Moeda.formatar(valorDesconto);
  }

  /// Situação da vigência em relação a [hoje].
  SituacaoVigencia situacao(DateTime hoje) {
    if (vigInicio != null && hoje.isBefore(vigInicio!)) return SituacaoVigencia.futuro;
    if (vigFim != null && hoje.isAfter(vigFim!)) return SituacaoVigencia.encerrado;
    return SituacaoVigencia.vigente;
  }

  /// "Válido de 01/01/2026 a 31/12/2026", "Válido até ...", "Sem prazo"...
  String get descricaoVigencia {
    final inicio = vigInicio == null ? null : Datas.formatar(vigInicio!);
    final fim = vigFim == null ? null : Datas.formatar(vigFim!);
    if (inicio != null && fim != null) return 'Válido de $inicio a $fim';
    if (fim != null) return 'Válido até $fim';
    if (inicio != null) return 'Válido a partir de $inicio';
    return 'Sem prazo de validade';
  }

  static String _semZeros(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '').replaceAll('.', ',');
}

enum SituacaoVigencia { vigente, futuro, encerrado }

/// Dados do formulário de criar ou editar um benefício.
class DadosBeneficio {
  const DadosBeneficio({
    required this.nome,
    required this.tipoDesconto,
    required this.valorDesconto,
    required this.planoIds,
    this.descricao,
    this.parceiro,
    this.vigInicio,
    this.vigFim,
    this.manterLogo = true,
    this.logo,
    this.logoTipo,
  });

  final String nome;
  final String? descricao;
  final String? parceiro;
  final TipoDesconto tipoDesconto;
  final double valorDesconto;
  final DateTime? vigInicio;
  final DateTime? vigFim;
  final List<String> planoIds;

  /// `true` mantém o logo atual; senão, [logo] é o novo (ou `null` para remover).
  final bool manterLogo;
  final Uint8List? logo;
  final String? logoTipo;

  Map<String, Object?> paraJson() => {
    'nome': nome,
    'descricao': descricao,
    'parceiro': parceiro,
    'tipoDesconto': tipoDesconto == TipoDesconto.percentual ? 'PERCENTUAL' : 'VALOR',
    'valorDesconto': valorDesconto,
    'vigInicio': vigInicio == null ? null : Datas.paraApi(vigInicio!),
    'vigFim': vigFim == null ? null : Datas.paraApi(vigFim!),
    'planoIds': planoIds,
    if (!manterLogo) ...{'logo': logo == null ? null : base64Encode(logo!), 'logoTipo': logo == null ? null : logoTipo},
  };
}
