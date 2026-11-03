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

/// RF06: membros da organização, com busca e filtro por situação.
/// Com [filtroInicial], abre já filtrada (ex.: a seção "Ciclos e bloqueios").
class TelaMembros extends StatefulWidget {
  const TelaMembros({super.key, this.titulo = 'Membros', this.filtroInicial});

  final String titulo;
  final Set<SituacaoMembro>? filtroInicial;

  @override
  State<TelaMembros> createState() => _TelaMembrosState();
}

class _TelaMembrosState extends State<TelaMembros> {
  List<Membro>? _membros;
  String? _erro;
  String _busca = '';
  late final Set<SituacaoMembro> _filtro = {...?widget.filtroInicial};

  @override
  void initState() {
    super.initState();
    _carregar();
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

  List<Membro> _filtrados(List<Membro> membros, DateTime hoje) {
    final termo = _busca.trim().toLowerCase();
    return [
      for (final m in membros)
        if ((termo.isEmpty || m.nome.toLowerCase().contains(termo) || m.email.contains(termo)) &&
            (_filtro.isEmpty || _filtro.contains(m.situacao(hoje))))
          m,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
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
    final filtrados = _filtrados(membros, hoje);
    final contagem = <SituacaoMembro, int>{};
    for (final m in membros) {
      contagem.update(m.situacao(hoje), (n) => n + 1, ifAbsent: () => 1);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            key: const Key('campo-busca-membro'),
            decoration: const InputDecoration(
              hintText: 'Buscar por nome ou e-mail',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _busca = v),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              for (final s in SituacaoMembro.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${s.rotulo} (${contagem[s] ?? 0})'),
                    selected: _filtro.contains(s),
                    onSelected: (marcado) => setState(() => marcado ? _filtro.add(s) : _filtro.remove(s)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregar,
            child: filtrados.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 48),
                      AvisoTela(icone: Icons.search_off, texto: 'Nenhum membro encontrado com esses filtros.'),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _CartaoMembro(
                      membro: filtrados[i],
                      hoje: hoje,
                      aoTocar: () => _abrirDetalhe(filtrados[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CartaoMembro extends StatelessWidget {
  const _CartaoMembro({required this.membro, required this.hoje, required this.aoTocar});

  final Membro membro;
  final DateTime hoje;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final situacao = membro.situacao(hoje);

    return CartaoItem(
      aoTocar: aoTocar,
      esmaecido: situacao == SituacaoMembro.desativado,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AvatarMembro(membro),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membro.nome,
                    overflow: TextOverflow.ellipsis,
                    style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    situacao == SituacaoMembro.desativado
                        ? membro.planoNome
                        : '${membro.planoNome} · ${membro.vencimentoCurto(hoje)}',
                    overflow: TextOverflow.ellipsis,
                    style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SeloSituacao(situacao),
          ],
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
