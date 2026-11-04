import 'package:flutter/material.dart';

/// Ações sensíveis registradas na auditoria (RF16).
enum AcaoAuditoria {
  liberacaoCiclo('Pagamento confirmado', Icons.payments_outlined),
  bloqueioManual('Carteirinha bloqueada', Icons.block),
  desbloqueio('Carteirinha desbloqueada', Icons.lock_open_outlined),
  desativacaoMembro('Cadastro desativado', Icons.person_off_outlined),
  reativacaoMembro('Cadastro reativado', Icons.person_outline),
  edicaoPlano('Plano editado', Icons.edit_note);

  const AcaoAuditoria(this.rotulo, this.icone);

  final String rotulo;
  final IconData icone;

  /// "LIBERACAO_CICLO" → [liberacaoCiclo]
  static AcaoAuditoria daApi(String valor) {
    final camel = valor.toLowerCase().replaceAllMapped(RegExp(r'_(\w)'), (m) => m[1]!.toUpperCase());
    return AcaoAuditoria.values.byName(camel);
  }
}

/// Um registro imutável da auditoria.
class RegistroAuditoria {
  const RegistroAuditoria({
    required this.id,
    required this.acao,
    required this.descricao,
    required this.administradorNome,
    required this.dataHora,
    this.justificativa,
  });

  factory RegistroAuditoria.deJson(Map<String, dynamic> json) => RegistroAuditoria(
    id: json['id'] as String,
    acao: AcaoAuditoria.daApi(json['acao'] as String),
    descricao: json['descricao'] as String,
    justificativa: json['justificativa'] as String?,
    administradorNome: json['administradorNome'] as String,
    dataHora: DateTime.parse(json['dataHora'] as String).toLocal(),
  );

  final String id;
  final AcaoAuditoria acao;
  final String descricao;
  final String? justificativa;
  final String administradorNome;
  final DateTime dataHora;
}

/// Histórico de ações da organização (RF16).
abstract interface class AuditoriaRepositorio {
  Future<List<RegistroAuditoria>> listar();
}
