import '../../../core/formatacao/datas.dart';

/// Situação do membro como o administrador enxerga (RF05, RF07).
enum SituacaoMembro {
  emDia('Em dia'),
  venceEmBreve('Vence em breve'),
  vencido('Vencido'),
  bloqueado('Bloqueado'),
  desativado('Desativado');

  const SituacaoMembro(this.rotulo);

  final String rotulo;
}

enum StatusCarteirinha { ativa, bloqueada, invalidada }

/// Carteirinha digital do membro (RF05).
class Carteirinha {
  const Carteirinha({required this.status, required this.dataVencimento, required this.qrVersao});

  factory Carteirinha.deJson(Map<String, dynamic> json) => Carteirinha(
        status: StatusCarteirinha.values.byName((json['status'] as String).toLowerCase()),
        dataVencimento: DateTime.parse(json['dataVencimento'] as String),
        qrVersao: json['qrVersao'] as int,
      );

  final StatusCarteirinha status;
  final DateTime dataVencimento;

  /// Muda a cada liberação ou bloqueio; QR Codes de versões antigas deixam de valer.
  final int qrVersao;
}

/// Membro da organização (RF06).
class Membro {
  const Membro({
    required this.id,
    required this.nome,
    required this.email,
    required this.planoId,
    required this.planoNome,
    required this.planoDuracaoDias,
    required this.dataAdesao,
    required this.ativo,
    required this.carteirinha,
    this.telefone,
  });

  factory Membro.deJson(Map<String, dynamic> json) => Membro(
        id: json['id'] as String,
        nome: json['nome'] as String,
        email: json['email'] as String,
        telefone: json['telefone'] as String?,
        planoId: json['planoId'] as String,
        planoNome: json['planoNome'] as String,
        planoDuracaoDias: json['planoDuracaoDias'] as int,
        dataAdesao: DateTime.parse(json['dataAdesao'] as String),
        ativo: json['status'] == 'ATIVO',
        carteirinha: Carteirinha.deJson(json['carteirinha'] as Map<String, dynamic>),
      );

  /// Quantos dias antes do vencimento o membro aparece como "Vence em breve".
  static const diasAviso = 7;

  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String planoId;
  final String planoNome;

  /// Duração do ciclo do plano atual, usada no próximo pagamento.
  final int planoDuracaoDias;
  final DateTime dataAdesao;
  final bool ativo;
  final Carteirinha carteirinha;

  SituacaoMembro situacao(DateTime hoje) {
    if (!ativo) return SituacaoMembro.desativado;
    if (carteirinha.status == StatusCarteirinha.bloqueada) return SituacaoMembro.bloqueado;
    final dias = diasParaVencer(hoje);
    if (dias < 0) return SituacaoMembro.vencido;
    if (dias <= diasAviso) return SituacaoMembro.venceEmBreve;
    return SituacaoMembro.emDia;
  }

  /// Dias até o vencimento (negativo se já venceu).
  int diasParaVencer(DateTime hoje) => carteirinha.dataVencimento.difference(hoje).inDays;

  /// "Vence hoje", "Vence em 4 dias", "Venceu há 10 dias"...
  String descricaoVencimento(DateTime hoje) {
    final dias = diasParaVencer(hoje);
    final data = Datas.formatar(carteirinha.dataVencimento);
    if (dias == 0) return 'Vence hoje ($data)';
    if (dias == 1) return 'Vence amanhã ($data)';
    if (dias > 1) return 'Vence em $data';
    if (dias == -1) return 'Venceu ontem ($data)';
    return 'Venceu há ${-dias} dias ($data)';
  }

  /// Versão curta, para listas: "Vence hoje", "Vence em 07/11/2026", "Venceu em 24/10/2026".
  String vencimentoCurto(DateTime hoje) {
    final dias = diasParaVencer(hoje);
    if (dias == 0) return 'Vence hoje';
    final data = Datas.formatar(carteirinha.dataVencimento);
    return dias > 0 ? 'Vence em $data' : 'Venceu em $data';
  }

  /// Vencimento depois de confirmar um pagamento feito em [dataPagamento]:
  /// conta do vencimento atual ou do pagamento (o que for maior), mais a
  /// duração do plano. Mesma regra da função liberar_ciclo do banco.
  DateTime novoVencimento(DateTime dataPagamento) {
    final base = dataPagamento.isAfter(carteirinha.dataVencimento) ? dataPagamento : carteirinha.dataVencimento;
    return DateTime(base.year, base.month, base.day + planoDuracaoDias);
  }

  /// Cópia com outra carteirinha ou outro status (usada pelo repositório simulado).
  Membro copyWith({Carteirinha? carteirinha, bool? ativo}) => Membro(
        id: id,
        nome: nome,
        email: email,
        telefone: telefone,
        planoId: planoId,
        planoNome: planoNome,
        planoDuracaoDias: planoDuracaoDias,
        dataAdesao: dataAdesao,
        ativo: ativo ?? this.ativo,
        carteirinha: carteirinha ?? this.carteirinha,
      );

  /// Iniciais para o avatar: "Marina Membro" → "MM".
  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+'));
    final primeira = partes.first.isEmpty ? '?' : partes.first[0];
    return (partes.length > 1 ? '$primeira${partes.last[0]}' : primeira).toUpperCase();
  }
}

/// Dados do formulário de cadastrar ou editar um membro.
class DadosMembro {
  const DadosMembro({required this.nome, required this.email, required this.planoId, this.telefone});

  final String nome;
  final String email;
  final String? telefone;
  final String planoId;

  Map<String, Object?> paraJson() => {'nome': nome, 'email': email, 'telefone': telefone, 'planoId': planoId};
}

/// Resposta do cadastro: o membro e a senha provisória para repassar a ele.
class MembroCriado {
  const MembroCriado(this.membro, this.senhaProvisoria);

  final Membro membro;
  final String senhaProvisoria;
}
