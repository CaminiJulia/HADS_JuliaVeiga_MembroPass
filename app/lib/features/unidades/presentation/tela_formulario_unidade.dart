import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../auth/presentation/widgets/aviso_erro.dart';
import '../../planos/domain/plano.dart';
import '../../planos/presentation/seletor_planos.dart';
import '../domain/unidade_evento.dart';

/// Cria ou edita uma unidade ou evento. Fecha devolvendo o local salvo.
class TelaFormularioUnidade extends StatefulWidget {
  const TelaFormularioUnidade({super.key, this.local, required this.planos});

  final UnidadeEvento? local;
  final List<Plano> planos;

  @override
  State<TelaFormularioUnidade> createState() => _TelaFormularioUnidadeState();
}

class _TelaFormularioUnidadeState extends State<TelaFormularioUnidade> {
  final _formulario = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.local?.nome);
  late final _localizacao = TextEditingController(text: widget.local?.localizacao);
  late var _tipo = widget.local?.tipo ?? TipoLocal.unidade;
  late DateTime? _inicio = widget.local?.dataInicio;
  late DateTime? _fim = widget.local?.dataFim;

  /// Novo local já aceita todos os planos ativos; o administrador desmarca se quiser.
  late final Set<String> _planoIds = widget.local == null
      ? {
          for (final p in widget.planos)
            if (p.ativo) p.id,
        }
      : {...widget.local!.planoIds};

  late Uint8List? _imagem = widget.local?.imagem;
  late String? _imagemTipo = widget.local?.imagemTipo;
  bool _imagemAlterada = false;

  static const _tamanhoMaximoImagem = 512 * 1024;

  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.local != null;

  @override
  void dispose() {
    _nome.dispose();
    _localizacao.dispose();
    super.dispose();
  }

  Future<void> _escolherData({required bool inicio}) async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: (inicio ? _inicio : _fim ?? _inicio) ?? Datas.hoje(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: inicio ? 'Início do evento' : 'Fim do evento',
    );
    if (escolhida == null) return;
    setState(() {
      if (inicio) {
        _inicio = escolhida;
        // Evento de um dia: o fim acompanha o início se ainda não foi escolhido.
        if (_fim == null || _fim!.isBefore(escolhida)) _fim = escolhida;
      } else {
        _fim = escolhida;
      }
    });
  }

  Future<void> _escolherImagem() async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _tamanhoMaximoImagem) {
      avisar(context, 'A imagem pode ter no máximo 512 KB.');
      return;
    }
    setState(() {
      _imagem = bytes;
      _imagemTipo = arquivo.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      _imagemAlterada = true;
    });
  }

  void _removerImagem() => setState(() {
    _imagem = null;
    _imagemTipo = null;
    _imagemAlterada = true;
  });

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    final evento = _tipo == TipoLocal.evento;
    if (evento && (_inicio == null || _fim == null)) {
      setState(() => _erro = 'Informe o início e o fim do evento.');
      return;
    }
    if (evento && _fim!.isBefore(_inicio!)) {
      setState(() => _erro = 'O fim do evento não pode ser antes do início.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _salvando = true;
      _erro = null;
    });

    final localizacao = _localizacao.text.trim();
    final dados = DadosUnidadeEvento(
      nome: _nome.text.trim(),
      tipo: _tipo,
      localizacao: localizacao.isEmpty ? null : localizacao,
      dataInicio: evento ? _inicio : null,
      dataFim: evento ? _fim : null,
      planoIds: _planoIds.toList(),
      manterImagem: !_imagemAlterada,
      imagem: _imagem,
      imagemTipo: _imagemTipo,
    );
    final repositorio = context.read<UnidadesRepositorio>();
    try {
      final salvo = _editando ? await repositorio.editar(widget.local!.id, dados) : await repositorio.criar(dados);
      if (mounted) Navigator.of(context).pop(salvo);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = mensagemDeErro(e);
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final titulo = texto.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta);
    final evento = _tipo == TipoLocal.evento;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar local' : 'Novo local')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_erro != null) ...[AvisoErro(mensagem: _erro!), const SizedBox(height: 16)],
                    SegmentedButton<TipoLocal>(
                      segments: const [
                        ButtonSegment(
                          value: TipoLocal.unidade,
                          icon: Icon(Icons.store_mall_directory_outlined),
                          label: Text('Unidade'),
                        ),
                        ButtonSegment(value: TipoLocal.evento, icon: Icon(Icons.event_outlined), label: Text('Evento')),
                      ],
                      selected: {_tipo},
                      onSelectionChanged: _salvando ? null : (s) => setState(() => _tipo = s.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo-nome-local'),
                      controller: _nome,
                      enabled: !_salvando,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 150,
                      decoration: InputDecoration(
                        labelText: evento ? 'Nome do evento' : 'Nome da unidade',
                        hintText: evento ? 'Ex.: Torneio de Verão' : 'Ex.: Sede Central',
                        counterText: '',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _localizacao,
                      enabled: !_salvando,
                      maxLength: 255,
                      decoration: const InputDecoration(
                        labelText: 'Endereço ou local (opcional)',
                        prefixIcon: Icon(Icons.place_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(evento ? 'Banner do evento' : 'Foto do local', style: titulo),
                    const SizedBox(height: 4),
                    Text(
                      'Opcional. Aparece como capa do cartão; de preferência na horizontal.',
                      style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                    ),
                    const SizedBox(height: 10),
                    _CampoImagem(
                      imagem: _imagem,
                      habilitado: !_salvando,
                      aoEscolher: _escolherImagem,
                      aoRemover: _removerImagem,
                    ),
                    if (evento) ...[
                      const SizedBox(height: 20),
                      Text('Período do evento', style: titulo),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CampoData(
                              rotulo: 'Início',
                              data: _inicio,
                              aoEscolher: _salvando ? null : () => _escolherData(inicio: true),
                              aoLimpar: _salvando ? null : () => setState(() => _inicio = null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CampoData(
                              rotulo: 'Fim',
                              data: _fim,
                              aoEscolher: _salvando ? null : () => _escolherData(inicio: false),
                              aoLimpar: _salvando ? null : () => setState(() => _fim = null),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('Planos aceitos', style: titulo),
                    const SizedBox(height: 4),
                    Text(
                      'O operador só aprova o check-in de membros destes planos.',
                      style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                    ),
                    const SizedBox(height: 8),
                    SeletorPlanos(
                      planos: widget.planos,
                      selecionados: _planoIds,
                      habilitado: !_salvando,
                      aoAlterar: (id, marcado) => setState(() => marcado ? _planoIds.add(id) : _planoIds.remove(id)),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      key: const Key('botao-salvar-local'),
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando ? const CarregandoBotao() : Text(_editando ? 'Salvar alterações' : 'Cadastrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Prévia da capa (16:7) com os botões de escolher, trocar e remover.
class _CampoImagem extends StatelessWidget {
  const _CampoImagem({
    required this.imagem,
    required this.habilitado,
    required this.aoEscolher,
    required this.aoRemover,
  });

  final Uint8List? imagem;
  final bool habilitado;
  final VoidCallback aoEscolher;
  final VoidCallback aoRemover;

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(16);
    if (imagem == null) {
      return InkWell(
        key: const Key('botao-imagem-local'),
        onTap: habilitado ? aoEscolher : null,
        borderRadius: raio,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Cores.superficie,
            borderRadius: raio,
            border: Border.all(color: Cores.borda),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: Cores.primaria, size: 32),
              SizedBox(height: 6),
              Text(
                'Escolher imagem',
                style: TextStyle(color: Cores.primaria, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: raio,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: Image.memory(imagem!, fit: BoxFit.cover, width: double.infinity),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Row(
              children: [
                _BotaoSobreImagem(
                  icone: Icons.edit_outlined,
                  dica: 'Trocar imagem',
                  aoTocar: habilitado ? aoEscolher : null,
                ),
                const SizedBox(width: 8),
                _BotaoSobreImagem(
                  icone: Icons.delete_outline,
                  dica: 'Remover imagem',
                  aoTocar: habilitado ? aoRemover : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoSobreImagem extends StatelessWidget {
  const _BotaoSobreImagem({required this.icone, required this.dica, required this.aoTocar});

  final IconData icone;
  final String dica;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: dica,
        onPressed: aoTocar,
        icon: Icon(icone, color: Colors.white, size: 20),
      ),
    );
  }
}
