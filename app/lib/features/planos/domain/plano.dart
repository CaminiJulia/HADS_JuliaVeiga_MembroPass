import 'dart:ui';

import '../../../core/tema/contraste.dart';

/// Plano de associação da organização (RF04).
class Plano {
  const Plano({
    required this.id,
    required this.nome,
    required this.valorReferencia,
    required this.duracaoDias,
    required this.ativo,
    this.cor,
  });

  factory Plano.deJson(Map<String, dynamic> json) => Plano(
    id: json['id'] as String,
    nome: json['nome'] as String,
    valorReferencia: (json['valorReferencia'] as num).toDouble(),
    duracaoDias: json['duracaoDias'] as int,
    ativo: json['status'] == 'ATIVO',
    cor: json['cor'] as String?,
  );

  final String id;
  final String nome;

  /// Valor combinado fora do app; serve só de referência (o app não cobra).
  final double valorReferencia;

  /// Duração de cada ciclo, usada para calcular o novo vencimento.
  final int duracaoDias;

  /// Plano inativo não aceita novos membros, mas não afeta os já vinculados.
  final bool ativo;

  /// Cor de identificação ("#RRGGBB"); `null` usa a cor padrão do app.
  final String? cor;

  Color? get corDefinida => cor == null ? null : Contraste.lerHex(cor!);

  Plano copyWith({String? nome, double? valorReferencia, int? duracaoDias, bool? ativo, String? Function()? cor}) =>
      Plano(
        id: id,
        nome: nome ?? this.nome,
        valorReferencia: valorReferencia ?? this.valorReferencia,
        duracaoDias: duracaoDias ?? this.duracaoDias,
        ativo: ativo ?? this.ativo,
        cor: cor == null ? this.cor : cor(),
      );
}

/// Dados do formulário de criar ou editar um plano.
class DadosPlano {
  const DadosPlano({required this.nome, required this.valorReferencia, required this.duracaoDias, this.cor});

  final String nome;
  final double valorReferencia;
  final int duracaoDias;
  final String? cor;

  Map<String, Object?> paraJson() => {
    'nome': nome,
    'valorReferencia': valorReferencia,
    'duracaoDias': duracaoDias,
    'cor': cor,
  };
}
