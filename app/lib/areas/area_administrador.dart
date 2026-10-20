import 'package:flutter/material.dart';

import '../auth/usuario.dart';
import 'area_base.dart';

// Painel do administrador da organização. Até a habilitação feita pela equipe
// MembroPass, mostra apenas o status do cadastro (RF03, HU01).
class AreaAdministrador extends StatelessWidget {
  const AreaAdministrador({super.key, required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    return AreaBase(
      usuario: usuario,
      titulo: 'Painel da organização',
      corpo: usuario.organizacao.habilitada
          ? const EmConstrucao(
              icone: Icons.dashboard_outlined,
              mensagem: 'Planos, membros, benefícios e unidades aparecem aqui em breve.',
            )
          : const EmConstrucao(
              icone: Icons.hourglass_top,
              mensagem: 'Sua organização está em habilitação.\n'
                  'Você terá acesso ao painel completo assim que a equipe MembroPass concluir a análise.',
            ),
    );
  }
}
