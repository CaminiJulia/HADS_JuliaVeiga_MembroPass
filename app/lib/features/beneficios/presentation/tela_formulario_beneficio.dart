import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/formatacao/moeda.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../auth/presentation/widgets/aviso_erro.dart';
import '../../planos/domain/plano.dart';
import '../domain/beneficio.dart';
import '../domain/beneficios_repositorio.dart';

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

  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.beneficio != null;

  /// Planos que podem ser escolhidos: os ativos e os já vinculados (mesmo se inativos).
  List<Plano> get _planosVisiveis =>
      [for (final p in widget.planos) if (p.ativo || _planoIds.contains(p.id)) p];

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
    );
    final repositorio = context.read<BeneficiosRepositorio>();
    try {
      final salvo = _editando
          ? await repositorio.editar(widget.beneficio!.id, dados)
          : await repositorio.criar(dados);
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

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar benefício' : 'Novo benefício')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_erro != null) ...[
                      AvisoErro(mensagem: _erro!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const Key('campo-nome-beneficio'),
                      controller: _nome,
                      enabled: !_salvando,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Nome do benefício',
                        hintText: 'Ex.: Desconto na farmácia',
                        counterText: '',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome do benefício.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _parceiro,
                      enabled: !_salvando,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 150,
                      decoration: const InputDecoration(labelText: 'Parceiro (opcional)', counterText: ''),
                    ),
                    const SizedBox(height: 20),
                    Text('Desconto', style: titulo),
                    const SizedBox(height: 8),
                    SegmentedButton<TipoDesconto>(
                      segments: const [
                        ButtonSegment(value: TipoDesconto.percentual, label: Text('Percentual (%)')),
                        ButtonSegment(value: TipoDesconto.valor, label: Text('Valor (R\$)')),
                      ],
                      selected: {_tipo},
                      onSelectionChanged: _salvando ? null : (s) => setState(() => _tipo = s.first),
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
                        prefixText: _tipo == TipoDesconto.valor ? 'R\$ ' : null,
                        suffixText: _tipo == TipoDesconto.percentual ? '%' : null,
                      ),
                      validator: _validarValor,
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
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Vigência', style: titulo),
                    const SizedBox(height: 4),
                    Text(
                      'Deixe em branco para o benefício valer sem prazo.',
                      style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _CampoData(
                            rotulo: 'Início',
                            data: _inicio,
                            aoEscolher: _salvando ? null : () => _escolherData(inicio: true),
                            aoLimpar: _salvando ? null : () => setState(() => _inicio = null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CampoData(
                            rotulo: 'Fim',
                            data: _fim,
                            aoEscolher: _salvando ? null : () => _escolherData(inicio: false),
                            aoLimpar: _salvando ? null : () => setState(() => _fim = null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Planos com direito', style: titulo),
                    const SizedBox(height: 8),
                    if (_planosVisiveis.isEmpty)
                      Text(
                        'Cadastre um plano primeiro para vincular este benefício.',
                        style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final plano in _planosVisiveis)
                            FilterChip(
                              label: Text(plano.nome),
                              selected: _planoIds.contains(plano.id),
                              onSelected: _salvando
                                  ? null
                                  : (marcado) => setState(
                                        () => marcado ? _planoIds.add(plano.id) : _planoIds.remove(plano.id),
                                      ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 28),
                    FilledButton(
                      key: const Key('botao-salvar-beneficio'),
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando
                          ? const CarregandoBotao()
                          : Text(_editando ? 'Salvar alterações' : 'Criar benefício'),
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

class _CampoData extends StatelessWidget {
  const _CampoData({required this.rotulo, required this.data, this.aoEscolher, this.aoLimpar});

  final String rotulo;
  final DateTime? data;
  final VoidCallback? aoEscolher;
  final VoidCallback? aoLimpar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoEscolher,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: rotulo,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: data == null
              ? null
              : IconButton(tooltip: 'Limpar $rotulo', icon: const Icon(Icons.close), onPressed: aoLimpar),
        ),
        child: Text(data == null ? '—' : Datas.formatar(data!)),
      ),
    );
  }
}
