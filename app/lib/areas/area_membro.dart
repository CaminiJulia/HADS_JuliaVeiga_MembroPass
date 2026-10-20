import 'package:flutter/material.dart';

import '../auth/usuario.dart';
import 'area_base.dart';

// Área do membro: carteirinha digital e benefícios do plano (RF05, RF09).
class AreaMembro extends StatelessWidget {
  const AreaMembro({super.key, required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    return AreaBase(
      usuario: usuario,
      titulo: 'Minha carteirinha',
      corpo: EmConstrucao(
        icone: Icons.qr_code_2,
        mensagem: 'Olá, ${usuario.nome}!\nSua carteirinha digital aparece aqui em breve.',
      ),
    );
  }
}
