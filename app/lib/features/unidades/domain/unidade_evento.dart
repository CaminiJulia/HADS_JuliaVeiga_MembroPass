import 'dart:convert';
import 'dart:typed_data';

import '../../../core/formatacao/datas.dart';

enum TipoLocal { unidade, evento }

/// Momento do evento em relação a hoje.
enum SituacaoEvento { futuro, acontecendo, encerrado }

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
    this.imagem,
    this.imagemTipo,
  });

  factory UnidadeEvento.deJson(Map<String, dynamic> json) => UnidadeEvento(
    id: json['id'] as String,
    nome: json['nome'] as String,
    tipo: json['tipo'] == 'EVENTO' ? TipoLocal.evento : TipoLocal.unidade,
    localizacao: json['localizacao'] as String?,
    dataInicio: Datas.daApi(json['dataInicio'] as String?),
    dataFim: Datas.daApi(json['dataFim'] as String?),
    planoIds: [for (final id in json['planoIds'] as List) id as String],
    imagem: json['imagem'] == null ? null : base64Decode(json['imagem'] as String),
    imagemTipo: json['imagemTipo'] as String?,
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

  /// Foto do local ou banner do evento (PNG ou JPEG), usada como capa.
  final Uint8List? imagem;
  final String? imagemTipo;

  bool get evento => tipo == TipoLocal.evento;

  /// Evento cujo período já terminou.
  bool encerrado(DateTime hoje) => evento && dataFim != null && hoje.isAfter(dataFim!);

  /// `null` para unidades (que não têm período).
  SituacaoEvento? situacao(DateTime hoje) {
    if (!evento || dataInicio == null || dataFim == null) return null;
    if (hoje.isBefore(dataInicio!)) return SituacaoEvento.futuro;
    if (hoje.isAfter(dataFim!)) return SituacaoEvento.encerrado;
    return SituacaoEvento.acontecendo;
  }

  /// Dias até o evento começar (0 se já começou).
  int diasParaComecar(DateTime hoje) =>
      dataInicio == null || !hoje.isBefore(dataInicio!) ? 0 : dataInicio!.difference(hoje).inDays;
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
    this.manterImagem = true,
    this.imagem,
    this.imagemTipo,
  });

  final String nome;
  final TipoLocal tipo;
  final String? localizacao;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final List<String> planoIds;

  /// `true` mantém a imagem atual; senão, [imagem] é a nova (ou `null` para remover).
  final bool manterImagem;
  final Uint8List? imagem;
  final String? imagemTipo;

  Map<String, Object?> paraJson() => {
    'nome': nome,
    'tipo': tipo == TipoLocal.evento ? 'EVENTO' : 'UNIDADE',
    'localizacao': localizacao,
    'dataInicio': dataInicio == null ? null : Datas.paraApi(dataInicio!),
    'dataFim': dataFim == null ? null : Datas.paraApi(dataFim!),
    'planoIds': planoIds,
    if (!manterImagem) ...{
      'imagem': imagem == null ? null : base64Encode(imagem!),
      'imagemTipo': imagem == null ? null : imagemTipo,
    },
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
