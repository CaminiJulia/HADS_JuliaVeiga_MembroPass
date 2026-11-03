import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/moeda.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../auth/presentation/widgets/aviso_erro.dart';
import '../domain/plano.dart';
import '../domain/planos_repositorio.dart';
import 'cor_plano.dart';

/// Cria um plano novo ou edita [plano], com prévia do cartão enquanto digita.
/// Fecha devolvendo o plano salvo.
class TelaFormularioPlano extends StatefulWidget {
  const TelaFormularioPlano({super.key, this.plano});

  final Plano? plano;

  /// Durações mais comuns, com o nome sugerido para o plano.
  static const atalhos = [(30, 'Mensal'), (90, 'Trimestral'), (180, 'Semestral'), (365, 'Anual')];

  @override
  State<TelaFormularioPlano> createState() => _TelaFormularioPlanoState();
}

class _TelaFormularioPlanoState extends State<TelaFormularioPlano> {
  final _formulario = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.plano?.nome);
  late final _valor = TextEditingController(
    text: widget.plano == null ? null : Moeda.paraCampo(widget.plano!.valorReferencia),
  );
  late final _duracao = TextEditingController(text: widget.plano?.duracaoDias.toString());

  late String? _cor = widget.plano?.cor;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.plano != null;

  @override
  void initState() {
    super.initState();
    // A prévia acompanha o que é digitado.
    for (final c in [_nome, _valor, _duracao]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _valor.dispose();
    _duracao.dispose();
    super.dispose();
  }

  void _usarAtalho(int dias, String nome) {
    _duracao.text = '$dias';
    if (_nome.text.trim().isEmpty) _nome.text = nome;
  }

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _salvando = true;
      _erro = null;
    });

    final dados = DadosPlano(
      nome: _nome.text.trim(),
      valorReferencia: Moeda.ler(_valor.text)!,
      duracaoDias: int.parse(_duracao.text),
      cor: _cor,
    );
    final repositorio = context.read<PlanosRepositorio>();
    try {
      final salvo = _editando ? await repositorio.editar(widget.plano!.id, dados) : await repositorio.criar(dados);
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
    final dias = int.tryParse(_duracao.text);

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar plano' : 'Novo plano')),
      // Botão fixo no rodapé: continua visível com o teclado aberto.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.viewInsetsOf(context).bottom),
          child: FilledButton(
            key: const Key('botao-salvar-plano'),
            onPressed: _salvando ? null : _salvar,
            child: _salvando ? const CarregandoBotao() : Text(_editando ? 'Salvar alterações' : 'Criar plano'),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formulario,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _PreviaPlano(nome: _nome.text.trim(), valor: Moeda.ler(_valor.text), dias: dias, cor: _cor),
                const SizedBox(height: 20),
                if (_erro != null) ...[AvisoErro(mensagem: _erro!), const SizedBox(height: 16)],
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Text(
                    'DADOS DO PLANO',
                    style: texto.labelMedium?.copyWith(
                      color: Cores.textoSecundario,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextFormField(
                  key: const Key('campo-nome-plano'),
                  controller: _nome,
                  enabled: !_salvando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nome do plano',
                    hintText: 'Ex.: Mensal, Família, Estudante',
                    prefixIcon: Icon(Icons.label_outline),
                    counterText: '',
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome do plano.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('campo-valor-plano'),
                  controller: _valor,
                  enabled: !_salvando,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: const InputDecoration(
                    labelText: 'Valor de referência',
                    hintText: '0,00',
                    prefixIcon: Icon(Icons.payments_outlined),
                    prefixText: 'R\$ ',
                    helperText: 'Quanto o membro paga por ciclo.',
                  ),
                  validator: (v) => Moeda.ler(v ?? '') == null ? 'Informe um valor válido, ex.: 89,90.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('campo-duracao-plano'),
                  controller: _duracao,
                  enabled: !_salvando,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Duração do ciclo',
                    hintText: '30',
                    prefixIcon: Icon(Icons.event_repeat_outlined),
                    suffixText: 'dias',
                  ),
                  validator: (v) {
                    final dias = int.tryParse(v ?? '');
                    if (dias == null || dias < 1) return 'Informe pelo menos 1 dia.';
                    if (dias > 3650) return 'O máximo é 3650 dias.';
                    return null;
                  },
                  onFieldSubmitted: (_) => _salvar(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (d, nome) in TelaFormularioPlano.atalhos)
                      ChoiceChip(
                        key: Key('atalho-$d'),
                        label: Text('$d dias'),
                        tooltip: nome,
                        selected: dias == d,
                        onSelected: _salvando ? null : (_) => _usarAtalho(d, nome),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Text(
                    'COR DO PLANO',
                    style: texto.labelMedium?.copyWith(
                      color: Cores.textoSecundario,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text('Identifica o plano nas listas de planos e de membros.', style: texto.bodySmall),
                ),
                SeletorCorPlano(
                  selecionada: _cor,
                  habilitado: !_salvando,
                  aoEscolher: (cor) => setState(() => _cor = cor),
                ),
                const SizedBox(height: 24),
                const CaixaInfo(
                  'O pagamento é combinado fora do app. O valor serve de referência, e a duração '
                  'define o novo vencimento quando você confirmar um pagamento.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Como o plano vai aparecer, atualizado a cada tecla.
class _PreviaPlano extends StatelessWidget {
  const _PreviaPlano({required this.nome, required this.valor, required this.dias, required this.cor});

  final String nome;
  final double? valor;
  final int? dias;

  /// Cor do plano; `null` usa o azul da marca.
  final String? cor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final diasValidos = dias != null && dias! > 0;
    final porMes = valor != null && diasValidos && dias != 30 ? valor! * 30 / dias! : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // A cor do plano escurecida o necessário para o texto branco continuar legível.
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: degradeDoPlano(cor)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nome.isEmpty ? 'Seu plano' : nome,
                  overflow: TextOverflow.ellipsis,
                  style: texto.titleMedium?.copyWith(
                    color: nome.isEmpty ? Colors.white54 : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text('PRÉVIA', style: texto.labelSmall?.copyWith(color: Colors.white70, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Valores grandes encolhem em vez de estourar a linha.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valor == null ? 'R\$ —' : Moeda.formatar(valor!),
                    style: texto.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                diasValidos ? '/ ${dias == 1 ? '1 dia' : '$dias dias'}' : '/ — dias',
                style: texto.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          if (porMes != null) ...[
            const SizedBox(height: 4),
            Text('≈ ${Moeda.formatar(porMes)} por mês', style: texto.bodySmall?.copyWith(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}
