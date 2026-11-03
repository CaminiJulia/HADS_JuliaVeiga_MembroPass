import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../domain/membro.dart';
import '../domain/membros_repositorio.dart';
import 'tela_detalhe_membro.dart';
import 'tela_formulario_membro.dart';
import 'widgets/visual_membro.dart';

/// Filtros da lista de membros. Cada um reúne uma ou mais situações.
enum FiltroMembros {
  todos('Todos', {}),
  atencao('Precisam de atenção', {SituacaoMembro.venceEmBreve, SituacaoMembro.vencido, SituacaoMembro.bloqueado}),
  emDia('Em dia', {SituacaoMembro.emDia}),
  venceEmBreve('Vence em breve', {SituacaoMembro.venceEmBreve}),
  vencidos('Vencidos', {SituacaoMembro.vencido}),
  bloqueados('Bloqueados', {SituacaoMembro.bloqueado}),
  desativados('Desativados', {SituacaoMembro.desativado});

  const FiltroMembros(this.rotulo, this.situacoes);

  final String rotulo;

  /// Vazio em [todos]: aceita qualquer situação.
  final Set<SituacaoMembro> situacoes;

  bool aceita(SituacaoMembro s) => situacoes.isEmpty || situacoes.contains(s);
}

enum _Ordem {
  nome('Nome (A–Z)'),
  vencimento('Vencimento (mais urgente)');

  const _Ordem(this.rotulo);

  final String rotulo;
}

/// RF06: membros da organização, com busca, filtro por situação e ordenação.
/// Com [filtroInicial], abre já filtrada (ex.: a seção "Ciclos e bloqueios").
class TelaMembros extends StatefulWidget {
  const TelaMembros({super.key, this.titulo = 'Membros', this.filtroInicial = FiltroMembros.todos});

  final String titulo;
  final FiltroMembros filtroInicial;

  @override
  State<TelaMembros> createState() => _TelaMembrosState();
}

class _TelaMembrosState extends State<TelaMembros> {
  final _campoBusca = TextEditingController();
  List<Membro>? _membros;
  String? _erro;
  late var _filtro = widget.filtroInicial;
  // Em "atenção", quem vence antes aparece primeiro.
  late var _ordem = widget.filtroInicial == FiltroMembros.atencao ? _Ordem.vencimento : _Ordem.nome;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _campoBusca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final membros = await context.read<MembrosRepositorio>().listar();
      if (mounted) setState(() => _membros = membros);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  Future<void> _novoMembro() async {
    final criado = await Navigator.of(context).push<MembroCriado>(
      MaterialPageRoute(builder: (_) => const TelaFormularioMembro()),
    );
    if (criado == null || !mounted) return;
    await _carregar();
    if (mounted) await mostrarSenhaProvisoria(context, criado);
  }

  Future<void> _abrirDetalhe(Membro membro) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => TelaDetalheMembro(membroId: membro.id)),
    );
    if (mounted) await _carregar();
  }

  List<Membro> _visiveis(List<Membro> membros, DateTime hoje) {
    final termo = _campoBusca.text.trim().toLowerCase();
    final lista = [
      for (final m in membros)
        if ((termo.isEmpty || m.nome.toLowerCase().contains(termo) || m.email.contains(termo)) &&
            _filtro.aceita(m.situacao(hoje)))
          m,
    ];
    lista.sort(switch (_ordem) {
      _Ordem.nome => (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      _Ordem.vencimento => (a, b) => a.carteirinha.dataVencimento.compareTo(b.carteirinha.dataVencimento),
    });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          PopupMenuButton<_Ordem>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.sort),
            initialValue: _ordem,
            onSelected: (o) => setState(() => _ordem = o),
            itemBuilder: (_) => [
              for (final o in _Ordem.values)
                CheckedPopupMenuItem(value: o, checked: o == _ordem, child: Text(o.rotulo)),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: _membros == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _novoMembro,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Novo membro'),
            ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_erro != null) return AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar);
    final membros = _membros;
    if (membros == null) return const Center(child: CircularProgressIndicator());
    if (membros.isEmpty) {
      return const AvisoTela(
        icone: Icons.people_outline,
        texto: 'Nenhum membro ainda.\nCadastre o primeiro para emitir a carteirinha dele.',
      );
    }

    final hoje = Datas.hoje();
    final visiveis = _visiveis(membros, hoje);
    final situacoes = [for (final m in membros) m.situacao(hoje)];
    int contar(FiltroMembros f) => situacoes.where(f.aceita).length;
    final filtrando = _filtro != FiltroMembros.todos || _campoBusca.text.trim().isNotEmpty;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _CampoBusca(controlador: _campoBusca, aoMudar: () => setState(() {})),
            ),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                children: [
                  for (final f in FiltroMembros.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ChipFiltro(
                        filtro: f,
                        quantidade: contar(f),
                        selecionado: f == _filtro,
                        aoTocar: () => setState(() => _filtro = f),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _carregar,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                      child: Text(
                        filtrando
                            ? '${visiveis.length} de ${membros.length} membros'
                            : '${membros.length} ${membros.length == 1 ? 'membro' : 'membros'}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Cores.textoSecundario),
                      ),
                    ),
                    if (visiveis.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: AvisoTela(icone: Icons.search_off, texto: 'Nenhum membro encontrado com esses filtros.'),
                      )
                    else
                      CartaoItem(
                        child: Column(
                          children: [
                            for (final (i, m) in visiveis.indexed) ...[
                              if (i > 0) const Divider(indent: 72),
                              _LinhaMembro(membro: m, hoje: hoje, aoTocar: () => _abrirDetalhe(m)),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoBusca extends StatelessWidget {
  const _CampoBusca({required this.controlador, required this.aoMudar});

  final TextEditingController controlador;
  final VoidCallback aoMudar;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('campo-busca-membro'),
      controller: controlador,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nome ou e-mail',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        suffixIcon: controlador.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close),
                onPressed: () {
                  controlador.clear();
                  aoMudar();
                },
              ),
      ),
      onChanged: (_) => aoMudar(),
    );
  }
}

/// Chip de filtro com o rótulo e um contador em destaque.
class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({required this.filtro, required this.quantidade, required this.selecionado, required this.aoTocar});

  final FiltroMembros filtro;
  final int quantidade;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${filtro.rotulo}: $quantidade',
      selected: selecionado,
      button: true,
      excludeSemantics: true,
      child: ChoiceChip(
        key: Key('filtro-${filtro.name}'),
        showCheckmark: false,
        selected: selecionado,
        onSelected: (_) => aoTocar(),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(filtro.rotulo),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: selecionado ? Cores.primaria : Cores.borda,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$quantidade',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selecionado ? Cores.noPrimaria : Cores.tinta,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaMembro extends StatelessWidget {
  const _LinhaMembro({required this.membro, required this.hoje, required this.aoTocar});

  final Membro membro;
  final DateTime hoje;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final situacao = membro.situacao(hoje);
    final desativado = situacao == SituacaoMembro.desativado;

    return InkWell(
      onTap: aoTocar,
      child: Opacity(
        opacity: desativado ? 0.6 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              AvatarMembro(membro, raio: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membro.nome,
                      overflow: TextOverflow.ellipsis,
                      style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text('Plano ${membro.planoNome}', overflow: TextOverflow.ellipsis, style: texto.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Situação e data à direita, alinhadas: o selo diz se venceu, a data diz quando.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SeloSituacao(situacao),
                  if (!desativado) ...[
                    const SizedBox(height: 4),
                    Text(
                      Datas.formatar(membro.carteirinha.dataVencimento),
                      style: texto.bodySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Cores.textoSecundario, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mostra a senha provisória do membro recém-cadastrado, com opção de copiar.
Future<void> mostrarSenhaProvisoria(BuildContext context, MembroCriado criado) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.verified_user_outlined, color: Cores.sucesso),
      title: Text('Cadastro de ${criado.membro.nome} criado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('A carteirinha já foi emitida. Repasse ao membro o e-mail e a senha provisória para o primeiro acesso:'),
          const SizedBox(height: 16),
          SelectableText(criado.membro.email, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Cores.fundo, borderRadius: BorderRadius.circular(12)),
            child: SelectableText(
              criado.senhaProvisoria,
              key: const Key('senha-provisoria'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta senha não será mostrada de novo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Cores.textoSecundario, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: criado.senhaProvisoria));
            avisar(context, 'Senha copiada.');
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copiar senha'),
        ),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Pronto')),
      ],
    ),
  );
}
