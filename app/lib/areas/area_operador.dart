import 'package:flutter/material.dart';

import '../auth/usuario.dart';
import 'area_base.dart';

// Área do operador: exclusivamente a leitura do QR Code e o check-in (RF02, RF10).
class AreaOperador extends StatelessWidget {
  const AreaOperador({super.key, required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    return AreaBase(
      usuario: usuario,
      titulo: 'Validar check-in',
      corpo: const EmConstrucao(
        icone: Icons.qr_code_scanner,
        mensagem: 'A leitura do QR Code das carteirinhas aparece aqui em breve.',
      ),
    );
  }
}
