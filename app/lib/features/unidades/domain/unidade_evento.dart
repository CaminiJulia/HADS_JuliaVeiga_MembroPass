import '../../../core/formatacao/datas.dart';

enum TipoLocal { unidade, evento }

/// Local fixo (unidade) ou evento com período, onde a carteirinha vale (RF11).
class UnidadeEvento {
  const UnidadeEvento({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.planoIds,
    this.localizacao,
    this.dataInicio,
    this.dataFim,
  });

  factory UnidadeEvento.deJson(Map<String, dynamic> json) => UnidadeEvento(
        id: json['id'] as String,
        nome: json['nome'] as String,
        tipo: json['tipo'] == 'EVENTO' ? TipoLocal.evento : TipoLocal.unidade,
        localizacao: json['localizacao'] as String?,
        dataInicio: Datas.daApi(json['dataInicio'] as String?),
        dataFim: Datas.daApi(json['dataFim'] as String?),
        planoIds: [for (final id in json['planoIds'] as List) id as String],
      );

  final String id;
  final String nome;
  final TipoLocal tipo;
  final String? localizacao;

  /// Só para eventos.
  final DateTime? dataInicio;
  final DateTime? dataFim;

  /// Planos aceitos neste local; o check-in recusa os demais (RF10).
  final List<String> planoIds;

  bool get evento => tipo == TipoLocal.evento;

  /// Evento cujo período já terminou.
  bool encerrado(DateTime hoje) => evento && dataFim != null && hoje.isAfter(dataFim!);

  /// "01/12/2026", ou "01/12/2026 a 03/12/2026"
  String? get periodo {
    if (!evento || dataInicio == null || dataFim == null) return null;
    final inicio = Datas.formatar(dataInicio!);
    return dataInicio == dataFim ? inicio : '$inicio a ${Datas.formatar(dataFim!)}';
  }
}

/// Dados do formulário de criar ou editar uma unidade ou evento.
class DadosUnidadeEvento {
  const DadosUnidadeEvento({
    required this.nome,
    required this.tipo,
    required this.planoIds,
    this.localizacao,
    this.dataInicio,
    this.dataFim,
  });

  final String nome;
  final TipoLocal tipo;
  final String? localizacao;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final List<String> planoIds;

  Map<String, Object?> paraJson() => {
        'nome': nome,
        'tipo': tipo == TipoLocal.evento ? 'EVENTO' : 'UNIDADE',
        'localizacao': localizacao,
        'dataInicio': dataInicio == null ? null : Datas.paraApi(dataInicio!),
        'dataFim': dataFim == null ? null : Datas.paraApi(dataFim!),
        'planoIds': planoIds,
      };
}

/// Unidades e eventos da organização (RF11).
/// Em caso de erro, lança `ErroApi` com a mensagem pronta para exibir.
abstract interface class UnidadesRepositorio {
  Future<List<UnidadeEvento>> listar();
  Future<UnidadeEvento> criar(DadosUnidadeEvento dados);
  Future<UnidadeEvento> editar(String id, DadosUnidadeEvento dados);
  Future<void> excluir(String id);
}
