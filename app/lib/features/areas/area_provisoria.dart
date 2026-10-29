import 'package:flutter/material.dart';

import '../../core/rotas.dart';
import '../../core/tema/cores.dart';
import '../auth/domain/usuario.dart';

/// Tela de destino provisória de cada papel, até a área real ser implementada.
class AreaProvisoria extends StatelessWidget {
  const AreaProvisoria({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.icone,
  });

  final String titulo;
  final String descricao;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final usuario = ModalRoute.of(context)?.settings.arguments as Usuario?;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushReplacementNamed(Rotas.login),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 64, color: Cores.primaria),
              const SizedBox(height: 16),
              if (usuario != null)
                Text(
                  'Olá, ${usuario.nome}',
                  style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 8),
              Text(
                descricao,
                textAlign: TextAlign.center,
                style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
