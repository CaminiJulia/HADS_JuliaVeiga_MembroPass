import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/moeda.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../beneficios/domain/beneficios_repositorio.dart';
import '../../membros/domain/membros_repositorio.dart';
import '../domain/plano.dart';
import '../domain/planos_repositorio.dart';
import 'cor_plano.dart';
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
    final salvo = await Navigator.of(
      context,
    ).push<Plano>(MaterialPageRoute(builder: (_) => TelaFormularioPlano(plano: plano)));
    if (salvo == null || !mounted) return;
    avisar(context, plano == null ? 'Plano "${salvo.nome}" criado.' : 'Plano "${salvo.nome}" atualizado.');
    await _carregar();
  }

  Future<void> _alterarAtivo(Plano plano) async {
    if (plano.ativo &&
        !await confirmar(
          context,
          titulo: 'Desativar "${plano.nome}"?',
          mensagem:
              'Novos membros não poderão ser vinculados a este plano. '
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
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, size: 18, color: Cores.lilas),
                    const SizedBox(width: 8),
                    Text(
                      ativos == planos.length
                          ? '$ativos ${ativos == 1 ? 'plano ativo' : 'planos ativos'}'
                          : '$ativos de ${planos.length} planos ativos',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              for (final plano in planos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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

/// Cartão do plano no estilo da carteirinha: degradê na cor do plano com o
/// preço em destaque e, embaixo, quantos membros e benefícios ele tem.
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
    final cor = corDoPlano(plano.cor);
    const branco70 = Color(0xB3FFFFFF);

    return Opacity(
      opacity: plano.ativo ? 1 : 0.55,
      child: Material(
        color: Cores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Cores.borda),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoEditar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: degradeDoPlano(plano.cor),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Selo grande e apagado no canto, como na carteirinha.
                    const Positioned(
                      right: -18,
                      bottom: -28,
                      child: Icon(Icons.workspace_premium, size: 130, color: Color(0x14FFFFFF)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 4, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.workspace_premium_outlined, size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  plano.nome,
                                  overflow: TextOverflow.ellipsis,
                                  style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                              if (!plano.ativo)
                                Selo('Inativo', cor: Colors.black.withValues(alpha: 0.35), corTexto: Colors.white),
                              PopupMenuButton<VoidCallback>(
                                tooltip: 'Opções',
                                iconColor: Colors.white,
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
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                // Valores grandes encolhem em vez de estourar a linha.
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      Moeda.formatar(plano.valorReferencia),
                                      style: texto.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '/ ${plano.duracaoDias == 1 ? '1 dia' : '${plano.duracaoDias} dias'}',
                                  style: texto.bodyMedium?.copyWith(color: branco70),
                                ),
                              ],
                            ),
                          ),
                          if (plano.duracaoDias != 30) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '≈ ${Moeda.formatar(_porMes)}/mês',
                                style: texto.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(
                  children: [
                    _Contagem(
                      icone: Icons.people_alt_outlined,
                      cor: cor,
                      texto: membros == 1 ? '1 membro' : '$membros membros',
                    ),
                    const SizedBox(width: 20),
                    _Contagem(
                      icone: Icons.redeem_outlined,
                      cor: cor,
                      texto: beneficios == 1 ? '1 benefício' : '$beneficios benefícios',
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Cores.textoSecundario),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Contagem extends StatelessWidget {
  const _Contagem({required this.icone, required this.cor, required this.texto});

  final IconData icone;
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 18, color: corEscuraDemais(cor) ? Cores.textoSecundario : cor),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
