import 'package:flutter/material.dart';

import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../planos/domain/plano.dart';
import '../../planos/presentation/cor_plano.dart';
import '../domain/beneficio.dart';
import 'logo_parceiro.dart';

/// Cartão no estilo de cupom: selo do desconto à esquerda e, ao lado,
/// nome, situação, parceiro, validade e os planos com direito.
class CartaoBeneficio extends StatelessWidget {
  const CartaoBeneficio({
    super.key,
    required this.beneficio,
    required this.situacao,
    required this.planos,
    this.aoEditar,
    this.aoExcluir,
    this.mostrarPlanos = true,
  });

  /// O membro só vê os próprios benefícios: os planos com direito não importam.
  final bool mostrarPlanos;

  final Beneficio beneficio;
  final SituacaoVigencia situacao;
  final List<Plano> planos;

  /// Sem ações (`null`), o cartão serve de prévia: sem toque e sem menu.
  final VoidCallback? aoEditar;
  final VoidCallback? aoExcluir;

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
            LogoParceiro(logo: beneficio.logo, iniciais: beneficio.iniciais),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(beneficio.nome, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [_PilulaDesconto(beneficio), _SeloVigencia(situacao)],
                  ),
                  const SizedBox(height: 10),
                  if (parceiro != null) _Detalhe(icone: Icons.storefront_outlined, texto: parceiro),
                  _Detalhe(icone: Icons.event_outlined, texto: beneficio.descricaoVigencia),
                  if (mostrarPlanos) const SizedBox(height: 8),
                  if (!mostrarPlanos)
                    const SizedBox.shrink()
                  else if (planos.isEmpty)
                    Text(
                      'Nenhum plano vinculado',
                      style: texto.bodySmall?.copyWith(color: Cores.erro, fontWeight: FontWeight.w600),
                    )
                  else
                    Wrap(spacing: 6, runSpacing: 6, children: [for (final p in planos) EtiquetaPlano(p)]),
                ],
              ),
            ),
            if (aoEditar != null && aoExcluir != null)
              PopupMenuButton<VoidCallback>(
                tooltip: 'Opções',
                onSelected: (acao) => acao(),
                itemBuilder: (_) => [
                  PopupMenuItem(value: aoEditar, child: const Text('Editar')),
                  PopupMenuItem(value: aoExcluir, child: const Text('Excluir')),
                ],
              )
            else
              const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

/// O desconto em destaque: "15% de desconto", "R\$ 50 de desconto".
class _PilulaDesconto extends StatelessWidget {
  const _PilulaDesconto(this.beneficio);

  final Beneficio beneficio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Cores.marca, Cores.marcaEscura]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer_outlined, size: 14, color: Cores.lilas),
          const SizedBox(width: 5),
          Text(
            '${beneficio.valorCurto} de desconto',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
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
