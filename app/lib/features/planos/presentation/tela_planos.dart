import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/cliente_api.dart';
import '../../../core/formatacao/moeda.dart';
import '../../../core/tema/cores.dart';
import '../domain/plano.dart';
import '../domain/planos_repositorio.dart';
import 'tela_formulario_plano.dart';

/// RF04: lista os planos da organização, com criar, editar, ativar e desativar.
class TelaPlanos extends StatefulWidget {
  const TelaPlanos({super.key});

  @override
  State<TelaPlanos> createState() => _TelaPlanosState();
}

class _TelaPlanosState extends State<TelaPlanos> {
  List<Plano>? _planos;
  String? _erro;

  PlanosRepositorio get _repositorio => context.read<PlanosRepositorio>();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final planos = await _repositorio.listar();
      if (mounted) setState(() => _planos = planos);
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagem(e));
    }
  }

  Future<void> _abrirFormulario([Plano? plano]) async {
    final salvo = await Navigator.of(context).push<Plano>(
      MaterialPageRoute(builder: (_) => TelaFormularioPlano(plano: plano)),
    );
    if (salvo == null || !mounted) return;
    _avisar(plano == null ? 'Plano "${salvo.nome}" criado.' : 'Plano "${salvo.nome}" atualizado.');
    await _carregar();
  }

  Future<void> _alterarAtivo(Plano plano) async {
    if (plano.ativo && !await _confirmarDesativacao(plano)) return;
    try {
      await _repositorio.alterarAtivo(plano.id, ativo: !plano.ativo);
      if (!mounted) return;
      _avisar(plano.ativo ? 'Plano "${plano.nome}" desativado.' : 'Plano "${plano.nome}" reativado.');
      await _carregar();
    } catch (e) {
      if (mounted) _avisar(_mensagem(e));
    }
  }

  Future<bool> _confirmarDesativacao(Plano plano) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desativar "${plano.nome}"?'),
        content: const Text(
          'Novos membros não poderão ser vinculados a este plano. '
          'Os membros que já estão nele continuam normalmente.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desativar')),
        ],
      ),
    );
    return confirmou ?? false;
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  static String _mensagem(Object erro) => erro is ErroApi
      ? erro.mensagem
      : 'Não foi possível falar com o servidor. Verifique sua conexão.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planos')),
      floatingActionButton: _planos == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Novo plano'),
            ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_erro != null) return _Aviso(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar);
    final planos = _planos;
    if (planos == null) return const Center(child: CircularProgressIndicator());
    if (planos.isEmpty) {
      return const _Aviso(
        icone: Icons.workspace_premium_outlined,
        texto: 'Nenhum plano ainda.\nCrie o primeiro para poder cadastrar membros.',
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: planos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _CartaoPlano(
          plano: planos[i],
          aoEditar: () => _abrirFormulario(planos[i]),
          aoAlterarAtivo: () => _alterarAtivo(planos[i]),
        ),
      ),
    );
  }
}

class _CartaoPlano extends StatelessWidget {
  const _CartaoPlano({required this.plano, required this.aoEditar, required this.aoAlterarAtivo});

  final Plano plano;
  final VoidCallback aoEditar;
  final VoidCallback aoAlterarAtivo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Material(
      color: Cores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoEditar,
        child: Opacity(
          opacity: plano.ativo ? 1 : 0.6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plano.nome,
                              overflow: TextOverflow.ellipsis,
                              style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta),
                            ),
                          ),
                          if (!plano.ativo) ...[
                            const SizedBox(width: 8),
                            const _SeloInativo(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Moeda.formatar(plano.valorReferencia)} · ${_duracao(plano.duracaoDias)}',
                        style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<VoidCallback>(
                  tooltip: 'Opções',
                  onSelected: (acao) => acao(),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: aoEditar, child: const Text('Editar')),
                    PopupMenuItem(
                      value: aoAlterarAtivo,
                      child: Text(plano.ativo ? 'Desativar' : 'Reativar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _duracao(int dias) => dias == 1 ? 'ciclo de 1 dia' : 'ciclo de $dias dias';
}

class _SeloInativo extends StatelessWidget {
  const _SeloInativo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Cores.borda, borderRadius: BorderRadius.circular(20)),
      child: Text('Inativo', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Cores.tinta)),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icone, required this.texto, this.aoTentarDeNovo});

  final IconData icone;
  final String texto;
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: Cores.lilas),
            const SizedBox(height: 16),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Cores.textoSecundario),
            ),
            if (aoTentarDeNovo != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: aoTentarDeNovo, child: const Text('Tentar de novo')),
            ],
          ],
        ),
      ),
    );
  }
}
