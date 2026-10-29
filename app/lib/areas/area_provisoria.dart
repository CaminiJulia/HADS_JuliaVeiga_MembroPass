import 'package:flutter/material.dart';

import '../auth/usuario.dart';

/// Destino provisório depois do login. Cada papel vai ganhar a sua área
/// própria nas próximas etapas: painel da organização, leitura de QR Code
/// do operador e carteirinha do membro (RF01).
class AreaProvisoria extends StatelessWidget {
  const AreaProvisoria({super.key, required this.usuario, required this.aoSair});

  final Usuario usuario;
  final VoidCallback aoSair;

  static const _destinos = {
    Papel.administrador: (Icons.dashboard_outlined, 'Painel da organização'),
    Papel.operador: (Icons.qr_code_scanner, 'Leitura de QR Code'),
    Papel.membro: (Icons.badge_outlined, 'Carteirinha digital'),
  };

  @override
  Widget build(BuildContext context) {
    final (icone, titulo) = _destinos[usuario.papel]!;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: aoSair)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 64, color: tema.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Olá, ${usuario.nome}', style: tema.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(usuario.papel.descricao, style: tema.textTheme.bodyMedium),
              const SizedBox(height: 24),
              const Text('Esta área será construída nas próximas etapas.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
