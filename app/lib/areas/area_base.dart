import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/sessao.dart';
import '../auth/usuario.dart';

// Estrutura comum às três áreas: barra com o nome da organização e o botão de sair.
class AreaBase extends ConsumerWidget {
  const AreaBase({super.key, required this.usuario, required this.titulo, required this.corpo});

  final Usuario usuario;
  final String titulo;
  final Widget corpo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo),
            Text(usuario.organizacao.nome, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessaoProvider.notifier).sair(),
          ),
        ],
      ),
      body: SafeArea(child: corpo),
    );
  }
}

// Conteúdo provisório das telas que chegam nas próximas semanas do cronograma.
class EmConstrucao extends StatelessWidget {
  const EmConstrucao({super.key, required this.icone, required this.mensagem});

  final IconData icone;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(mensagem, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
