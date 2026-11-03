import 'package:flutter/material.dart';

import '../../../../core/tema/cores.dart';
import '../../../../core/widgets/componentes.dart';
import '../../domain/membro.dart';

/// Selo colorido com a situação do membro.
class SeloSituacao extends StatelessWidget {
  const SeloSituacao(this.situacao, {super.key});

  final SituacaoMembro situacao;

  @override
  Widget build(BuildContext context) {
    final (fundo, texto) = switch (situacao) {
      SituacaoMembro.emDia => (Cores.sucessoFundo, Cores.sucesso),
      SituacaoMembro.venceEmBreve => (Cores.alertaFundo, Cores.alerta),
      SituacaoMembro.vencido || SituacaoMembro.bloqueado => (Cores.erroFundo, Cores.erro),
      SituacaoMembro.desativado => (Cores.borda, Cores.textoSecundario),
    };
    return Selo(situacao.rotulo, cor: fundo, corTexto: texto);
  }
}

/// Círculo com as iniciais do membro.
class AvatarMembro extends StatelessWidget {
  const AvatarMembro(this.membro, {super.key, this.raio = 22});

  final Membro membro;
  final double raio;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: raio,
      backgroundColor: Cores.lilas.withValues(alpha: 0.16),
      foregroundColor: Cores.primaria,
      child: Text(
        membro.iniciais,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: raio * 0.7),
      ),
    );
  }
}
