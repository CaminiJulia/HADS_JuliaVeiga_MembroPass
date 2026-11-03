import 'package:flutter/material.dart';

import '../../../core/tema/cores.dart';
import '../domain/plano.dart';
import 'cor_plano.dart';

/// Chips para marcar planos. Mostra os ativos e os já marcados (mesmo se inativos).
class SeletorPlanos extends StatelessWidget {
  const SeletorPlanos({
    super.key,
    required this.planos,
    required this.selecionados,
    required this.aoAlterar,
    this.habilitado = true,
  });

  final List<Plano> planos;
  final Set<String> selecionados;
  final void Function(String planoId, bool marcado) aoAlterar;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final visiveis = [
      for (final p in planos)
        if (p.ativo || selecionados.contains(p.id)) p,
    ];
    if (visiveis.isEmpty) {
      return Text(
        'Cadastre um plano primeiro.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Cores.textoSecundario),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final plano in visiveis)
          FilterChip(
            // Marcado, o chip mostra o ✓; desmarcado, o ponto na cor do plano.
            avatar: selecionados.contains(plano.id) ? null : PontoCorPlano(plano.cor, tamanho: 10),
            label: Text(plano.nome),
            selected: selecionados.contains(plano.id),
            onSelected: habilitado ? (marcado) => aoAlterar(plano.id, marcado) : null,
          ),
      ],
    );
  }
}
