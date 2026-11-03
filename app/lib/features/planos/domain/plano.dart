/// Plano de associação da organização (RF04).
class Plano {
  const Plano({
    required this.id,
    required this.nome,
    required this.valorReferencia,
    required this.duracaoDias,
    required this.ativo,
  });

  factory Plano.deJson(Map<String, dynamic> json) => Plano(
        id: json['id'] as String,
        nome: json['nome'] as String,
        valorReferencia: (json['valorReferencia'] as num).toDouble(),
        duracaoDias: json['duracaoDias'] as int,
        ativo: json['status'] == 'ATIVO',
      );

  final String id;
  final String nome;

  /// Valor combinado fora do app; serve só de referência (o app não cobra).
  final double valorReferencia;

  /// Duração de cada ciclo, usada para calcular o novo vencimento.
  final int duracaoDias;

  /// Plano inativo não aceita novos membros, mas não afeta os já vinculados.
  final bool ativo;

  Plano copyWith({String? nome, double? valorReferencia, int? duracaoDias, bool? ativo}) => Plano(
        id: id,
        nome: nome ?? this.nome,
        valorReferencia: valorReferencia ?? this.valorReferencia,
        duracaoDias: duracaoDias ?? this.duracaoDias,
        ativo: ativo ?? this.ativo,
      );
}

/// Dados do formulário de criar ou editar um plano.
class DadosPlano {
  const DadosPlano({required this.nome, required this.valorReferencia, required this.duracaoDias});

  final String nome;
  final double valorReferencia;
  final int duracaoDias;

  Map<String, Object> paraJson() => {
        'nome': nome,
        'valorReferencia': valorReferencia,
        'duracaoDias': duracaoDias,
      };
}
