import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../planos/domain/plano.dart';
import '../../planos/domain/planos_repositorio.dart';
import '../domain/beneficio.dart';
import '../domain/beneficios_repositorio.dart';
import 'tela_formulario_beneficio.dart';

/// RF08: benefícios da organização e os planos que dão direito a cada um.
class TelaBeneficios extends StatefulWidget {
  const TelaBeneficios({super.key});

  @override
  State<TelaBeneficios> createState() => _TelaBeneficiosState();
}

class _TelaBeneficiosState extends State<TelaBeneficios> {
  List<Beneficio>? _beneficios;
  List<Plano> _planos = const [];
  String? _erro;

  BeneficiosRepositorio get _repositorio => context.read<BeneficiosRepositorio>();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final (beneficios, planos) = await (
        _repositorio.listar(),
        context.read<PlanosRepositorio>().listar(),
      ).wait;
      if (mounted) {
        setState(() {
          _beneficios = beneficios;
          _planos = planos;
        });
      }
    } catch (e) {
      final erro = e is ParallelWaitError ? e.errors.$1 ?? e.errors.$2 : e;
      if (mounted) setState(() => _erro = mensagemDeErro(erro!));
    }
  }

  Future<void> _abrirFormulario([Beneficio? beneficio]) async {
    final salvo = await Navigator.of(context).push<Beneficio>(
      MaterialPageRoute(builder: (_) => TelaFormularioBeneficio(beneficio: beneficio, planos: _planos)),
    );
    if (salvo == null || !mounted) return;
    avisar(context, beneficio == null ? 'Benefício "${salvo.nome}" criado.' : 'Benefício "${salvo.nome}" atualizado.');
    await _carregar();
  }

  Future<void> _excluir(Beneficio beneficio) async {
    final confirmou = await confirmar(
      context,
      titulo: 'Excluir "${beneficio.nome}"?',
      mensagem: 'O benefício deixa de aparecer para os membros de todos os planos.',
      acao: 'Excluir',
    );
    if (!confirmou || !mounted) return;
    try {
      await _repositorio.excluir(beneficio.id);
      if (!mounted) return;
      avisar(context, 'Benefício "${beneficio.nome}" excluído.');
      await _carregar();
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benefícios')),
      floatingActionButton: _beneficios == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Novo benefício'),
            ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_erro != null) return AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar);
    final beneficios = _beneficios;
    if (beneficios == null) return const Center(child: CircularProgressIndicator());
    if (beneficios.isEmpty) {
      return const AvisoTela(
        icone: Icons.redeem_outlined,
        texto: 'Nenhum benefício ainda.\nCadastre descontos e vantagens para os seus membros.',
      );
    }

    final nomesPlanos = {for (final p in _planos) p.id: p.nome};
    final hoje = Datas.hoje();
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: beneficios.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _CartaoBeneficio(
          beneficio: beneficios[i],
          situacao: beneficios[i].situacao(hoje),
          nomesPlanos: [for (final id in beneficios[i].planoIds) ?nomesPlanos[id]],
          aoEditar: () => _abrirFormulario(beneficios[i]),
          aoExcluir: () => _excluir(beneficios[i]),
        ),
      ),
    );
  }
}

class _CartaoBeneficio extends StatelessWidget {
  const _CartaoBeneficio({
    required this.beneficio,
    required this.situacao,
    required this.nomesPlanos,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final Beneficio beneficio;
  final SituacaoVigencia situacao;
  final List<String> nomesPlanos;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final parceiro = beneficio.parceiro;

    return CartaoItem(
      aoTocar: aoEditar,
      esmaecido: situacao == SituacaoVigencia.encerrado,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          beneficio.nome,
                          overflow: TextOverflow.ellipsis,
                          style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta),
                        ),
                      ),
                      if (situacao == SituacaoVigencia.encerrado) ...[
                        const SizedBox(width: 8),
                        const Selo('Encerrado'),
                      ] else if (situacao == SituacaoVigencia.futuro) ...[
                        const SizedBox(width: 8),
                        const Selo('Em breve'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parceiro == null ? beneficio.descricaoDesconto : '${beneficio.descricaoDesconto} · $parceiro',
                    style: texto.bodyMedium?.copyWith(color: Cores.primaria, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    beneficio.descricaoVigencia,
                    style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nomesPlanos.isEmpty ? 'Nenhum plano vinculado' : 'Planos: ${nomesPlanos.join(', ')}',
                    style: texto.bodySmall?.copyWith(
                      color: nomesPlanos.isEmpty ? Cores.erro : Cores.textoSecundario,
                    ),
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
