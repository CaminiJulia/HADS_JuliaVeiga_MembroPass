import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../planos/domain/plano.dart';
import '../../planos/domain/planos_repositorio.dart';
import '../../planos/presentation/cor_plano.dart';
import '../domain/unidade_evento.dart';
import 'tela_formulario_unidade.dart';

enum _Filtro {
  todos('Todos'),
  unidades('Unidades'),
  eventos('Eventos');

  const _Filtro(this.rotulo);

  final String rotulo;
}

/// RF11: unidades e eventos da organização e os planos aceitos em cada um.
class TelaUnidades extends StatefulWidget {
  const TelaUnidades({super.key});

  @override
  State<TelaUnidades> createState() => _TelaUnidadesState();
}

class _TelaUnidadesState extends State<TelaUnidades> {
  List<UnidadeEvento>? _locais;
  List<Plano> _planos = const [];
  String? _erro;
  var _filtro = _Filtro.todos;

  UnidadesRepositorio get _repositorio => context.read<UnidadesRepositorio>();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final (locais, planos) = await (_repositorio.listar(), context.read<PlanosRepositorio>().listar()).wait;
      if (mounted) {
        setState(() {
          _locais = locais;
          _planos = planos;
        });
      }
    } catch (e) {
      final erro = e is ParallelWaitError ? e.errors.$1 ?? e.errors.$2 : e;
      if (mounted) setState(() => _erro = mensagemDeErro(erro!));
    }
  }

  Future<void> _abrirFormulario([UnidadeEvento? local]) async {
    final salvo = await Navigator.of(context).push<UnidadeEvento>(
      MaterialPageRoute(
        builder: (_) => TelaFormularioUnidade(local: local, planos: _planos),
      ),
    );
    if (salvo == null || !mounted) return;
    avisar(context, local == null ? '"${salvo.nome}" cadastrado.' : '"${salvo.nome}" atualizado.');
    await _carregar();
  }

  Future<void> _excluir(UnidadeEvento local) async {
    final confirmou = await confirmar(
      context,
      titulo: 'Excluir "${local.nome}"?',
      mensagem: 'Os operadores deixam de poder validar check-ins neste local.',
      acao: 'Excluir',
    );
    if (!confirmou || !mounted) return;
    try {
      await _repositorio.excluir(local.id);
      if (!mounted) return;
      avisar(context, '"${local.nome}" excluído.');
      await _carregar();
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unidades e eventos')),
      floatingActionButton: _locais == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Novo local'),
            ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_erro != null) return AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar);
    final locais = _locais;
    if (locais == null) return const Center(child: CircularProgressIndicator());
    if (locais.isEmpty) {
      return const AvisoTela(
        icone: Icons.place_outlined,
        texto: 'Nenhuma unidade ou evento ainda.\nCadastre onde a carteirinha pode ser usada.',
      );
    }

    final hoje = Datas.hoje();
    final unidades = [
      for (final l in locais)
        if (!l.evento) l,
    ];
    // Eventos por data; os encerrados vão para o fim.
    final eventos =
        [
          for (final l in locais)
            if (l.evento) l,
        ]..sort((a, b) {
          final fimA = a.encerrado(hoje), fimB = b.encerrado(hoje);
          if (fimA != fimB) return fimA ? 1 : -1;
          return (a.dataInicio ?? hoje).compareTo(b.dataInicio ?? hoje);
        });
    final texto = Theme.of(context).textTheme;

    Widget cartao(UnidadeEvento l) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _CartaoLocal(
        local: l,
        hoje: hoje,
        // Na mesma ordem da lista de planos.
        planos: [
          for (final p in _planos)
            if (l.planoIds.contains(p.id)) p,
        ],
        aoEditar: () => _abrirFormulario(l),
        aoExcluir: () => _excluir(l),
      ),
    );

    return RefreshIndicator(
      onRefresh: _carregar,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final f in _Filtro.values)
                    ChoiceChip(
                      key: Key('filtro-local-${f.name}'),
                      showCheckmark: false,
                      selected: f == _filtro,
                      onSelected: (_) => setState(() => _filtro = f),
                      label: Text(switch (f) {
                        _Filtro.todos => '${f.rotulo} · ${locais.length}',
                        _Filtro.unidades => '${f.rotulo} · ${unidades.length}',
                        _Filtro.eventos => '${f.rotulo} · ${eventos.length}',
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_filtro != _Filtro.eventos && unidades.isNotEmpty) ...[
                _TituloGrupo('Unidades', unidades.length),
                for (final l in unidades) cartao(l),
              ],
              if (_filtro != _Filtro.unidades && eventos.isNotEmpty) ...[
                _TituloGrupo('Eventos', eventos.length),
                for (final l in eventos) cartao(l),
              ],
              if ((_filtro == _Filtro.unidades && unidades.isEmpty) || (_filtro == _Filtro.eventos && eventos.isEmpty))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    _filtro == _Filtro.unidades ? 'Nenhuma unidade cadastrada.' : 'Nenhum evento cadastrado.',
                    textAlign: TextAlign.center,
                    style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
                  ),
                ),
              const SizedBox(height: 4),
              const CaixaInfo(
                'No check-in, o operador só aprova membros dos planos aceitos no local. '
                'Em eventos, a carteirinha só vale dentro do período.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TituloGrupo extends StatelessWidget {
  const _TituloGrupo(this.texto, this.quantidade);

  final String texto;
  final int quantidade;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Text(
        '${texto.toUpperCase()} · $quantidade',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Cores.textoSecundario,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CartaoLocal extends StatelessWidget {
  const _CartaoLocal({
    required this.local,
    required this.hoje,
    required this.planos,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final UnidadeEvento local;
  final DateTime hoje;
  final List<Plano> planos;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final situacao = local.situacao(hoje);
    final localizacao = local.localizacao;

    return CartaoItem(
      aoTocar: aoEditar,
      esmaecido: situacao == SituacaoEvento.encerrado,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            local.evento && local.dataInicio != null ? _FolhaCalendario(local.dataInicio!) : const _IconeUnidade(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(local.nome, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (situacao != null) ...[
                    const SizedBox(height: 6),
                    _SeloEvento(situacao, diasParaComecar: local.diasParaComecar(hoje)),
                  ],
                  const SizedBox(height: 8),
                  if (local.evento && local.dataInicio != null && local.dataFim != null)
                    _Detalhe(
                      icone: Icons.event_outlined,
                      texto: Datas.periodoPorExtenso(local.dataInicio!, local.dataFim!),
                    ),
                  if (localizacao != null) _Detalhe(icone: Icons.place_outlined, texto: localizacao),
                  const SizedBox(height: 6),
                  if (planos.isEmpty)
                    Text(
                      'Nenhum plano aceito',
                      style: texto.bodySmall?.copyWith(color: Cores.erro, fontWeight: FontWeight.w600),
                    )
                  else
                    Wrap(spacing: 6, runSpacing: 6, children: [for (final p in planos) EtiquetaPlano(p)]),
                ],
              ),
            ),
            PopupMenuButton<VoidCallback>(
              tooltip: 'Opções',
              onSelected: (acao) => acao(),
              itemBuilder: (_) => [
                PopupMenuItem(value: aoEditar, child: const Text('Editar')),
                PopupMenuItem(value: aoExcluir, child: const Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Folhinha de calendário com o mês e o dia de início do evento.
class _FolhaCalendario extends StatelessWidget {
  const _FolhaCalendario(this.data);

  final DateTime data;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      width: 60,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            color: Cores.marca,
            alignment: Alignment.center,
            child: Text(
              Datas.mesAbreviado(data.month),
              style: texto.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${data.day}',
              style: texto.headlineSmall?.copyWith(color: Cores.noPrimaria, fontWeight: FontWeight.w800, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconeUnidade extends StatelessWidget {
  const _IconeUnidade();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Cores.marca, Cores.marcaEscura],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 28),
    );
  }
}

class _SeloEvento extends StatelessWidget {
  const _SeloEvento(this.situacao, {required this.diasParaComecar});

  final SituacaoEvento situacao;
  final int diasParaComecar;

  @override
  Widget build(BuildContext context) {
    final (rotulo, cor) = switch (situacao) {
      SituacaoEvento.acontecendo => ('Acontecendo agora', Cores.sucesso),
      SituacaoEvento.futuro => (diasParaComecar == 1 ? 'Começa amanhã' : 'Em $diasParaComecar dias', Cores.primaria),
      SituacaoEvento.encerrado => ('Encerrado', Cores.textoSecundario),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.45)),
      ),
      child: Text(
        rotulo,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Detalhe extends StatelessWidget {
  const _Detalhe({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icone, size: 16, color: Cores.textoSecundario),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
