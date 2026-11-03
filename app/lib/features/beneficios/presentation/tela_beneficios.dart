import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../planos/domain/plano.dart';
import '../../planos/domain/planos_repositorio.dart';
import '../../planos/presentation/cor_plano.dart';
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
      final (beneficios, planos) = await (_repositorio.listar(), context.read<PlanosRepositorio>().listar()).wait;
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
      MaterialPageRoute(
        builder: (_) => TelaFormularioBeneficio(beneficio: beneficio, planos: _planos),
      ),
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

    final planos = {for (final p in _planos) p.id: p};
    final hoje = Datas.hoje();
    final vigentes = beneficios.where((b) => b.situacao(hoje) == SituacaoVigencia.vigente).length;
    final texto = Theme.of(context).textTheme;

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
                  '${beneficios.length} ${beneficios.length == 1 ? 'benefício' : 'benefícios'} · '
                  '$vigentes ${vigentes == 1 ? 'vigente' : 'vigentes'}',
                  style: texto.labelMedium?.copyWith(color: Cores.textoSecundario),
                ),
              ),
              for (final b in beneficios)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartaoBeneficio(
                    beneficio: b,
                    situacao: b.situacao(hoje),
                    planos: [for (final id in b.planoIds) ?planos[id]],
                    aoEditar: () => _abrirFormulario(b),
                    aoExcluir: () => _excluir(b),
                  ),
                ),
              const SizedBox(height: 4),
              const CaixaInfo(
                'Cada membro vê, no app, os benefícios vigentes do plano dele. '
                'Benefícios encerrados ou ainda não iniciados ficam ocultos.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cartão no estilo de cupom: selo do desconto à esquerda e, ao lado,
/// nome, situação, parceiro, validade e os planos com direito.
class _CartaoBeneficio extends StatelessWidget {
  const _CartaoBeneficio({
    required this.beneficio,
    required this.situacao,
    required this.planos,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final Beneficio beneficio;
  final SituacaoVigencia situacao;
  final List<Plano> planos;
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
        padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SeloDesconto(beneficio),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(beneficio.nome, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _SeloVigencia(situacao),
                  const SizedBox(height: 10),
                  if (parceiro != null) _Detalhe(icone: Icons.storefront_outlined, texto: parceiro),
                  _Detalhe(icone: Icons.event_outlined, texto: beneficio.descricaoVigencia),
                  const SizedBox(height: 8),
                  if (planos.isEmpty)
                    Text(
                      'Nenhum plano vinculado',
                      style: texto.bodySmall?.copyWith(color: Cores.erro, fontWeight: FontWeight.w600),
                    )
                  else
                    Wrap(spacing: 6, runSpacing: 6, children: [for (final p in planos) _EtiquetaPlano(p)]),
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

/// O desconto em destaque, como num cupom: "15%" ou "R\$ 50".
class _SeloDesconto extends StatelessWidget {
  const _SeloDesconto(this.beneficio);

  final Beneficio beneficio;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Cores.marca, Cores.marcaEscura],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              beneficio.valorCurto,
              style: texto.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text('desconto', style: texto.labelSmall?.copyWith(color: Cores.lilas, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _SeloVigencia extends StatelessWidget {
  const _SeloVigencia(this.situacao);

  final SituacaoVigencia situacao;

  @override
  Widget build(BuildContext context) {
    final (rotulo, cor) = switch (situacao) {
      SituacaoVigencia.vigente => ('Vigente', Cores.sucesso),
      SituacaoVigencia.futuro => ('Em breve', Cores.alerta),
      SituacaoVigencia.encerrado => ('Encerrado', Cores.textoSecundario),
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
        children: [
          Icon(icone, size: 16, color: Cores.textoSecundario),
          const SizedBox(width: 6),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// Plano com direito ao benefício, com o ponto na cor do plano.
class _EtiquetaPlano extends StatelessWidget {
  const _EtiquetaPlano(this.plano);

  final Plano plano;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Cores.fundo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Cores.borda),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PontoCorPlano(plano.cor, tamanho: 7),
          const SizedBox(width: 5),
          Text(plano.nome, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Cores.tinta)),
        ],
      ),
    );
  }
}
