import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../planos/domain/plano.dart';
import '../../planos/domain/planos_repositorio.dart';
import '../domain/unidade_evento.dart';
import 'tela_formulario_unidade.dart';

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
      MaterialPageRoute(builder: (_) => TelaFormularioUnidade(local: local, planos: _planos)),
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

    final nomesPlanos = {for (final p in _planos) p.id: p.nome};
    final hoje = Datas.hoje();
    final unidades = [for (final l in locais) if (!l.evento) l];
    final eventos = [for (final l in locais) if (l.evento) l];

    Widget cartao(UnidadeEvento l) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CartaoLocal(
            local: l,
            hoje: hoje,
            nomesPlanos: [for (final id in l.planoIds) ?nomesPlanos[id]],
            aoEditar: () => _abrirFormulario(l),
            aoExcluir: () => _excluir(l),
          ),
        );

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (unidades.isNotEmpty) ...[
            const _Titulo('Unidades'),
            for (final l in unidades) cartao(l),
          ],
          if (eventos.isNotEmpty) ...[
            const _Titulo('Eventos'),
            for (final l in eventos) cartao(l),
          ],
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta),
      ),
    );
  }
}

class _CartaoLocal extends StatelessWidget {
  const _CartaoLocal({
    required this.local,
    required this.hoje,
    required this.nomesPlanos,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final UnidadeEvento local;
  final DateTime hoje;
  final List<String> nomesPlanos;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final encerrado = local.encerrado(hoje);
    final detalhes = [?local.periodo, ?local.localizacao];

    return CartaoItem(
      aoTocar: aoEditar,
      esmaecido: encerrado,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(local.evento ? Icons.event_outlined : Icons.store_mall_directory_outlined, color: Cores.primaria),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          local.nome,
                          overflow: TextOverflow.ellipsis,
                          style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta),
                        ),
                      ),
                      if (encerrado) ...[const SizedBox(width: 8), const Selo('Encerrado')],
                    ],
                  ),
                  for (final d in detalhes)
                    Text(d, style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario)),
                  const SizedBox(height: 6),
                  Text(
                    nomesPlanos.isEmpty ? 'Nenhum plano aceito' : 'Aceita: ${nomesPlanos.join(', ')}',
                    style: texto.bodySmall?.copyWith(color: nomesPlanos.isEmpty ? Cores.erro : Cores.textoSecundario),
                  ),
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
