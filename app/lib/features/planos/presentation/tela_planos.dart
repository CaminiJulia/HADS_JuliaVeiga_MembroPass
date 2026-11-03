import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/moeda.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../beneficios/domain/beneficios_repositorio.dart';
import '../../membros/domain/membros_repositorio.dart';
import '../domain/plano.dart';
import '../domain/planos_repositorio.dart';
import 'tela_formulario_plano.dart';

/// RF04: planos da organização em cartões de preço, com quantos membros e
/// benefícios cada um tem. Permite criar, editar, desativar e reativar.
class TelaPlanos extends StatefulWidget {
  const TelaPlanos({super.key});

  @override
  State<TelaPlanos> createState() => _TelaPlanosState();
}

class _TelaPlanosState extends State<TelaPlanos> {
  List<Plano>? _planos;
  String? _erro;

  /// Membros ativos e benefícios por plano. Vazios se não carregarem:
  /// são complementares e não impedem de gerenciar os planos.
  Map<String, int> _membrosPorPlano = const {};
  Map<String, int> _beneficiosPorPlano = const {};

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
      if (mounted) setState(() => _erro = mensagemDeErro(e));
      return;
    }
    await _carregarContagens();
  }

  Future<void> _carregarContagens() async {
    try {
      final (membros, beneficios) = await (
        context.read<MembrosRepositorio>().listar(),
        context.read<BeneficiosRepositorio>().listar(),
      ).wait;
      final porMembros = <String, int>{};
      for (final m in membros.where((m) => m.ativo)) {
        porMembros.update(m.planoId, (n) => n + 1, ifAbsent: () => 1);
      }
      final porBeneficios = <String, int>{};
      for (final b in beneficios) {
        for (final id in b.planoIds) {
          porBeneficios.update(id, (n) => n + 1, ifAbsent: () => 1);
        }
      }
      if (!mounted) return;
      setState(() {
        _membrosPorPlano = porMembros;
        _beneficiosPorPlano = porBeneficios;
      });
    } catch (_) {
      // Sem as contagens, os cartões só não mostram os números.
    }
  }

  Future<void> _abrirFormulario([Plano? plano]) async {
    final salvo = await Navigator.of(context).push<Plano>(
      MaterialPageRoute(builder: (_) => TelaFormularioPlano(plano: plano)),
    );
    if (salvo == null || !mounted) return;
    avisar(context, plano == null ? 'Plano "${salvo.nome}" criado.' : 'Plano "${salvo.nome}" atualizado.');
    await _carregar();
  }

  Future<void> _alterarAtivo(Plano plano) async {
    if (plano.ativo &&
        !await confirmar(
          context,
          titulo: 'Desativar "${plano.nome}"?',
          mensagem: 'Novos membros não poderão ser vinculados a este plano. '
              'Os membros que já estão nele continuam normalmente.',
          acao: 'Desativar',
        )) {
      return;
    }
    try {
      await _repositorio.alterarAtivo(plano.id, ativo: !plano.ativo);
      if (!mounted) return;
      avisar(context, plano.ativo ? 'Plano "${plano.nome}" desativado.' : 'Plano "${plano.nome}" reativado.');
      await _carregar();
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    }
  }

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
    if (_erro != null) return AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar);
    final planos = _planos;
    if (planos == null) return const Center(child: CircularProgressIndicator());
    if (planos.isEmpty) {
      return const AvisoTela(
        icone: Icons.workspace_premium_outlined,
        texto: 'Nenhum plano ainda.\nCrie o primeiro para poder cadastrar membros.',
      );
    }

    final ativos = planos.where((p) => p.ativo).length;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Text(
                  ativos == planos.length
                      ? '$ativos ${ativos == 1 ? 'plano ativo' : 'planos ativos'}'
                      : '$ativos de ${planos.length} planos ativos',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Cores.textoSecundario),
                ),
              ),
              for (final plano in planos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartaoPlano(
                    plano: plano,
                    membros: _membrosPorPlano[plano.id] ?? 0,
                    beneficios: _beneficiosPorPlano[plano.id] ?? 0,
                    aoEditar: () => _abrirFormulario(plano),
                    aoAlterarAtivo: () => _alterarAtivo(plano),
                  ),
                ),
              const SizedBox(height: 4),
              const CaixaInfo(
                'O valor é só uma referência: o pagamento é combinado fora do app. '
                'A duração define o novo vencimento quando você confirma um pagamento.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cartão de preço do plano.
class _CartaoPlano extends StatelessWidget {
  const _CartaoPlano({
    required this.plano,
    required this.membros,
    required this.beneficios,
    required this.aoEditar,
    required this.aoAlterarAtivo,
  });

  final Plano plano;
  final int membros;
  final int beneficios;
  final VoidCallback aoEditar;
  final VoidCallback aoAlterarAtivo;

  /// Valor proporcional a 30 dias, para comparar planos de durações diferentes.
  double get _porMes => plano.valorReferencia * 30 / plano.duracaoDias;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return CartaoItem(
      aoTocar: aoEditar,
      esmaecido: !plano.ativo,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Cores.primaria.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium_outlined, size: 20, color: Cores.primaria),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plano.nome,
                    overflow: TextOverflow.ellipsis,
                    style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!plano.ativo) const Selo('Inativo', cor: Cores.borda, corTexto: Cores.textoSecundario),
                PopupMenuButton<VoidCallback>(
                  tooltip: 'Opções',
                  onSelected: (acao) => acao(),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: aoEditar, child: const Text('Editar')),
                    PopupMenuItem(value: aoAlterarAtivo, child: Text(plano.ativo ? 'Desativar' : 'Reativar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    Moeda.formatar(plano.valorReferencia),
                    style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ ${plano.duracaoDias == 1 ? '1 dia' : '${plano.duracaoDias} dias'}',
                    style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
                  ),
                  const Spacer(),
                  if (plano.duracaoDias != 30)
                    Text(
                      '≈ ${Moeda.formatar(_porMes)}/mês',
                      style: texto.labelMedium?.copyWith(color: Cores.textoSecundario),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                _Contagem(
                  icone: Icons.people_alt_outlined,
                  texto: membros == 1 ? '1 membro' : '$membros membros',
                ),
                const SizedBox(width: 20),
                _Contagem(
                  icone: Icons.redeem_outlined,
                  texto: beneficios == 1 ? '1 benefício' : '$beneficios benefícios',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Contagem extends StatelessWidget {
  const _Contagem({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 18, color: Cores.textoSecundario),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Cores.textoSecundario)),
      ],
    );
  }
}
