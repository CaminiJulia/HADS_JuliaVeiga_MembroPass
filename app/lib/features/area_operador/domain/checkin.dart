import 'dart:convert';
import 'dart:typed_data';

import '../../../core/formatacao/datas.dart';
import '../../unidades/domain/unidade_evento.dart';

/// Por que a API recusou a entrada (RF10).
enum MotivoRecusa {
  qrInvalido,
  qrDesatualizado,
  membroInativo,
  carteirinhaBloqueada,
  carteirinhaInvalidada,
  planoNaoAceito,
  numeroInvalido;

  /// 'PLANO_NAO_ACEITO' → [planoNaoAceito]; `null` continua `null`.
  static MotivoRecusa? daApi(String? codigo) {
    if (codigo == null) return null;
    final partes = codigo.toLowerCase().split('_');
    final nome = partes.first + partes.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
    return MotivoRecusa.values.byName(nome);
  }
}

/// Como o operador identificou a carteirinha.
sealed class IdentificacaoCarteirinha {
  const IdentificacaoCarteirinha();
}

/// Texto lido do QR Code (assinado pela API, com versão).
final class PorQr extends IdentificacaoCarteirinha {
  const PorQr(this.codigo);

  final String codigo;
}

/// Número impresso na carteirinha, digitado quando o QR Code não lê.
/// Não tem assinatura nem versão: o operador confere a foto com mais atenção.
final class PorNumero extends IdentificacaoCarteirinha {
  const PorNumero(this.numero);

  /// 8 caracteres de 0 a 9 e A a F, como em "Nº 38F29DBA".
  final String numero;

  static final formato = RegExp(r'^[0-9A-F]{8}$');
}

enum FormaCheckin {
  qr,
  numero;

  static FormaCheckin daApi(String? forma) => forma == 'NUMERO' ? numero : qr;
}

/// Como a leitura terminou, do ponto de vista do operador.
enum DesfechoCheckin {
  liberado,

  /// Liberado, mas com o pagamento vencido: o operador avisa o membro.
  /// Quem decide bloquear é a administração, nunca o sistema.
  liberadoComAlerta,
  recusado;

  static DesfechoCheckin de({required bool aprovado, required bool vencida}) =>
      !aprovado ? recusado : (vencida ? liberadoComAlerta : liberado);
}

/// O membro dono da carteirinha lida.
class MembroLido {
  const MembroLido({
    required this.nome,
    required this.numero,
    required this.planoNome,
    required this.dataVencimento,
    this.planoCor,
    this.foto,
  });

  factory MembroLido.deJson(Map<String, dynamic> json) => MembroLido(
    nome: json['nome'] as String,
    foto: json['foto'] == null ? null : base64Decode(json['foto'] as String),
    numero: json['numero'] as String,
    planoNome: json['planoNome'] as String,
    planoCor: json['planoCor'] as String?,
    dataVencimento: Datas.daApi(json['dataVencimento'] as String)!,
  );

  final String nome;

  /// Para o operador comparar o rosto com a foto da carteirinha.
  final Uint8List? foto;

  /// Número curto impresso na carteirinha do membro.
  final String numero;
  final String planoNome;
  final String? planoCor;
  final DateTime dataVencimento;
}

/// Resposta da API a uma leitura de QR Code.
class ResultadoCheckin {
  const ResultadoCheckin({
    required this.dataHora,
    required this.aprovado,
    this.motivo,
    this.mensagem,
    this.vencida = false,
    this.forma = FormaCheckin.qr,
    this.entradaAnteriorHoje,
    this.membro,
  });

  factory ResultadoCheckin.deJson(Map<String, dynamic> json) => ResultadoCheckin(
    dataHora: DateTime.parse(json['dataHora'] as String).toLocal(),
    aprovado: json['aprovado'] as bool,
    motivo: MotivoRecusa.daApi(json['motivo'] as String?),
    mensagem: json['mensagem'] as String?,
    vencida: json['vencida'] as bool? ?? false,
    forma: FormaCheckin.daApi(json['forma'] as String?),
    entradaAnteriorHoje: json['entradaAnteriorHoje'] == null
        ? null
        : DateTime.parse(json['entradaAnteriorHoje'] as String).toLocal(),
    membro: json['membro'] == null ? null : MembroLido.deJson(json['membro'] as Map<String, dynamic>),
  );

  final DateTime dataHora;
  final bool aprovado;
  final MotivoRecusa? motivo;

  /// Motivo da recusa, já pronto para mostrar.
  final String? mensagem;
  final bool vencida;
  final FormaCheckin forma;

  /// A mesma carteirinha já entrou hoje neste local (pode estar emprestada).
  final DateTime? entradaAnteriorHoje;

  /// `null` quando o QR Code ou o número não é de nenhuma carteirinha da organização.
  final MembroLido? membro;

  DesfechoCheckin get desfecho => DesfechoCheckin.de(aprovado: aprovado, vencida: vencida);
}

/// Uma linha do histórico de leituras do dia no local.
class RegistroCheckin {
  const RegistroCheckin({
    required this.id,
    required this.dataHora,
    required this.aprovado,
    this.motivo,
    this.mensagem,
    this.vencida = false,
    this.forma = FormaCheckin.qr,
    this.membroNome,
    this.planoNome,
    this.planoCor,
  });

  factory RegistroCheckin.deJson(Map<String, dynamic> json) => RegistroCheckin(
    id: json['id'] as String,
    dataHora: DateTime.parse(json['dataHora'] as String).toLocal(),
    aprovado: json['aprovado'] as bool,
    motivo: MotivoRecusa.daApi(json['motivo'] as String?),
    mensagem: json['mensagem'] as String?,
    vencida: json['vencida'] as bool? ?? false,
    forma: FormaCheckin.daApi(json['forma'] as String?),
    membroNome: json['membroNome'] as String?,
    planoNome: json['planoNome'] as String?,
    planoCor: json['planoCor'] as String?,
  );

  final String id;
  final DateTime dataHora;
  final bool aprovado;
  final MotivoRecusa? motivo;
  final String? mensagem;
  final bool vencida;
  final FormaCheckin forma;

  /// `null` quando o QR Code ou o número não foi reconhecido.
  final String? membroNome;
  final String? planoNome;
  final String? planoCor;

  DesfechoCheckin get desfecho => DesfechoCheckin.de(aprovado: aprovado, vencida: vencida);
}

/// Área do operador (RF02 e RF10): só o check-in.
/// Em caso de erro, lança `ErroApi` com a mensagem pronta para exibir.
abstract interface class OperadorRepositorio {
  /// Unidades e os eventos que acontecem hoje.
  Future<List<UnidadeEvento>> locais();

  /// Valida a carteirinha no local e registra a leitura, aprovada ou não.
  Future<ResultadoCheckin> registrar({required String localId, required IdentificacaoCarteirinha carteirinha});

  /// Leituras de hoje no local, as mais recentes primeiro.
  Future<List<RegistroCheckin>> checkinsDeHoje(String localId);
}
