import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/formatacao/moeda.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../auth/presentation/widgets/aviso_erro.dart';
import '../../planos/domain/plano.dart';
import '../../planos/presentation/seletor_planos.dart';
import '../domain/beneficio.dart';
import '../domain/beneficios_repositorio.dart';
import 'cartao_beneficio.dart';
import 'logo_parceiro.dart';

/// Cria um benefício novo ou edita [beneficio]. Fecha devolvendo o benefício salvo.
class TelaFormularioBeneficio extends StatefulWidget {
  const TelaFormularioBeneficio({super.key, this.beneficio, required this.planos});

  final Beneficio? beneficio;

  /// Planos da organização, para escolher quais dão direito ao benefício.
  final List<Plano> planos;

  @override
  State<TelaFormularioBeneficio> createState() => _TelaFormularioBeneficioState();
}

class _TelaFormularioBeneficioState extends State<TelaFormularioBeneficio> {
  final _formulario = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.beneficio?.nome);
  late final _parceiro = TextEditingController(text: widget.beneficio?.parceiro);
  late final _descricao = TextEditingController(text: widget.beneficio?.descricao);
  late final _valor = TextEditingController(
    text: widget.beneficio == null ? null : Moeda.paraCampo(widget.beneficio!.valorDesconto),
  );
  late var _tipo = widget.beneficio?.tipoDesconto ?? TipoDesconto.percentual;
  late DateTime? _inicio = widget.beneficio?.vigInicio;
  late DateTime? _fim = widget.beneficio?.vigFim;
  late final Set<String> _planoIds = {...?widget.beneficio?.planoIds};
  late Uint8List? _logo = widget.beneficio?.logo;
  late String? _logoTipo = widget.beneficio?.logoTipo;
  bool _logoAlterado = false;

  static const _tamanhoMaximoLogo = 256 * 1024;

  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.beneficio != null;

  /// Iniciais do parceiro digitado (ou do nome), para quando não há logo.
  String get _iniciais => Beneficio(
    id: '',
    nome: _nome.text.trim().isEmpty ? '?' : _nome.text,
    parceiro: _parceiro.text.trim().isEmpty ? null : _parceiro.text,
    tipoDesconto: _tipo,
    valorDesconto: 0,
    planoIds: const [],
  ).iniciais;

  @override
  void initState() {
    super.initState();
    for (final c in [_nome, _parceiro, _valor]) {
      c.addListener(() => setState(() {}));
    }
  }

  /// O benefício como vai aparecer na lista, com o que já foi preenchido.
  Beneficio get _previa => Beneficio(
    id: 'previa',
    nome: _nome.text.trim().isEmpty ? 'Nome do benefício' : _nome.text.trim(),
    parceiro: _parceiro.text.trim().isEmpty ? null : _parceiro.text.trim(),
    tipoDesconto: _tipo,
    valorDesconto: Moeda.ler(_valor.text) ?? 0,
    vigInicio: _inicio,
    vigFim: _fim,
    planoIds: _planoIds.toList(),
    logo: _logo,
  );

  @override
  void dispose() {
    _nome.dispose();
    _parceiro.dispose();
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _escolherData({required bool inicio}) async {
    final atual = inicio ? _inicio : _fim;
    final escolhida = await showDatePicker(
      context: context,
      initialDate: atual ?? (inicio ? null : _inicio) ?? Datas.hoje(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: inicio ? 'Início da vigência' : 'Fim da vigência',
    );
    if (escolhida == null) return;
    setState(() => inicio ? _inicio = escolhida : _fim = escolhida);
  }

  Future<void> _escolherLogo() async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 85,
    );
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _tamanhoMaximoLogo) {
      avisar(context, 'O logo pode ter no máximo 256 KB.');
      return;
    }
    setState(() {
      _logo = bytes;
      _logoTipo = arquivo.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      _logoAlterado = true;
    });
  }

  void _removerLogo() => setState(() {
    _logo = null;
    _logoTipo = null;
    _logoAlterado = true;
  });

  String? _validarValor(String? texto) {
    final valor = Moeda.ler(texto ?? '');
    if (valor == null || valor <= 0) return 'Informe um desconto maior que zero.';
    if (_tipo == TipoDesconto.percentual && valor > 100) return 'O percentual vai até 100%.';
    return null;
  }

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    if (_inicio != null && _fim != null && _fim!.isBefore(_inicio!)) {
      setState(() => _erro = 'O fim da vigência não pode ser antes do início.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _salvando = true;
      _erro = null;
    });

    String? opcional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final dados = DadosBeneficio(
      nome: _nome.text.trim(),
      parceiro: opcional(_parceiro),
      descricao: opcional(_descricao),
      tipoDesconto: _tipo,
      valorDesconto: Moeda.ler(_valor.text)!,
      vigInicio: _inicio,
      vigFim: _fim,
      planoIds: _planoIds.toList(),
      manterLogo: !_logoAlterado,
      logo: _logo,
      logoTipo: _logoTipo,
    );
    final repositorio = context.read<BeneficiosRepositorio>();
    try {
      final salvo = _editando ? await repositorio.editar(widget.beneficio!.id, dados) : await repositorio.criar(dados);
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
    final previa = _previa;
    final planosAtivos = [
      for (final p in widget.planos)
        if (p.ativo) p.id,
    ];
    final todosMarcados = planosAtivos.isNotEmpty && planosAtivos.every(_planoIds.contains);

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar benefício' : 'Novo benefício')),
      // Botão fixo no rodapé: continua visível com o teclado aberto.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.viewInsetsOf(context).bottom),
          child: FilledButton(
            key: const Key('botao-salvar-beneficio'),
            onPressed: _salvando ? null : _salvar,
            child: _salvando ? const CarregandoBotao() : Text(_editando ? 'Salvar alterações' : 'Criar benefício'),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formulario,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const _TituloSecao('Prévia', topo: 0),
                // O mesmo cartão da lista, atualizado enquanto o formulário é preenchido.
                CartaoBeneficio(
                  beneficio: previa,
                  situacao: previa.situacao(Datas.hoje()),
                  planos: [
                    for (final p in widget.planos)
                      if (_planoIds.contains(p.id)) p,
                  ],
                ),
                if (_erro != null) ...[const SizedBox(height: 16), AvisoErro(mensagem: _erro!)],
                const _TituloSecao('Benefício'),
                TextFormField(
                  key: const Key('campo-nome-beneficio'),
                  controller: _nome,
                  enabled: !_salvando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nome do benefício',
                    hintText: 'Ex.: Desconto na farmácia',
                    prefixIcon: Icon(Icons.redeem_outlined),
                    counterText: '',
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome do benefício.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricao,
                  enabled: !_salvando,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Como usar (opcional)',
                    hintText: 'Ex.: Apresente a carteirinha no caixa.',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                    counterText: '',
                  ),
                ),
                const _TituloSecao('Parceiro'),
                TextFormField(
                  controller: _parceiro,
                  enabled: !_salvando,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Nome do parceiro (opcional)',
                    hintText: 'Ex.: Farmácia Central',
                    prefixIcon: Icon(Icons.storefront_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                CartaoItem(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        LogoParceiro(logo: _logo, iniciais: _iniciais, tamanho: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Logo do parceiro', style: texto.titleSmall),
                              Text(
                                _logo == null ? 'Sem logo, mostramos as iniciais.' : 'PNG ou JPEG, até 256 KB.',
                                style: texto.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (_logo != null)
                          IconButton(
                            tooltip: 'Remover logo',
                            onPressed: _salvando ? null : _removerLogo,
                            color: Cores.erro,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        OutlinedButton(
                          key: const Key('botao-logo-beneficio'),
                          onPressed: _salvando ? null : _escolherLogo,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                          child: Text(_logo == null ? 'Escolher' : 'Trocar'),
                        ),
                      ],
                    ),
                  ),
                ),
                const _TituloSecao('Desconto'),
                SegmentedButton<TipoDesconto>(
                  segments: const [
                    ButtonSegment(value: TipoDesconto.percentual, icon: Icon(Icons.percent), label: Text('Percentual')),
                    ButtonSegment(
                      value: TipoDesconto.valor,
                      icon: Icon(Icons.payments_outlined),
                      label: Text('Valor (R\$)'),
                    ),
                  ],
                  selected: {_tipo},
                  showSelectedIcon: false,
                  onSelectionChanged: _salvando ? null : (sel) => setState(() => _tipo = sel.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('campo-valor-beneficio'),
                  controller: _valor,
                  enabled: !_salvando,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: InputDecoration(
                    labelText: _tipo == TipoDesconto.percentual ? 'Percentual de desconto' : 'Valor do desconto',
                    prefixIcon: const Icon(Icons.local_offer_outlined),
                    prefixText: _tipo == TipoDesconto.valor ? 'R\$ ' : null,
                    suffixText: _tipo == TipoDesconto.percentual ? '%' : null,
                  ),
                  validator: _validarValor,
                ),
                _TituloSecao('Vigência', ajuda: 'Deixe em branco para o benefício valer sem prazo.'),
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
                _TituloSecao(
                  'Planos com direito',
                  acao: planosAtivos.isEmpty
                      ? null
                      : TextButton(
                          onPressed: _salvando
                              ? null
                              : () =>
                                    setState(() => todosMarcados ? _planoIds.clear() : _planoIds.addAll(planosAtivos)),
                          child: Text(todosMarcados ? 'Nenhum' : 'Todos'),
                        ),
                ),
                SeletorPlanos(
                  planos: widget.planos,
                  selecionados: _planoIds,
                  habilitado: !_salvando,
                  aoAlterar: (id, marcado) => setState(() => marcado ? _planoIds.add(id) : _planoIds.remove(id)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de seção em caixa alta, com ajuda opcional e uma ação à direita.
class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto, {this.ajuda, this.acao, this.topo = 28});

  final String texto;
  final String? ajuda;
  final Widget? acao;
  final double topo;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, topo, 0, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto.toUpperCase(),
                  style: estilo.labelMedium?.copyWith(
                    color: Cores.textoSecundario,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (ajuda != null) ...[const SizedBox(height: 2), Text(ajuda!, style: estilo.bodySmall)],
              ],
            ),
          ),
          ?acao,
        ],
      ),
    );
  }
}
