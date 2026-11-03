import 'package:flutter/material.dart';

import '../../../../core/tema/cores.dart';
import '../../domain/membro.dart';

/// Cor que representa cada situação (selo, faixa do cartão e barra do ciclo).
Color corDaSituacao(SituacaoMembro situacao) => switch (situacao) {
      SituacaoMembro.emDia => Cores.sucesso,
      SituacaoMembro.venceEmBreve => Cores.alerta,
      SituacaoMembro.vencido || SituacaoMembro.bloqueado => Cores.erro,
      SituacaoMembro.desativado => Cores.textoSecundario,
    };

/// Selo com a situação do membro: fundo translúcido e borda na cor da situação.
class SeloSituacao extends StatelessWidget {
  const SeloSituacao(this.situacao, {super.key});

  final SituacaoMembro situacao;

  @override
  Widget build(BuildContext context) {
    final cor = corDaSituacao(situacao);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.45)),
      ),
      child: Text(
        situacao.rotulo,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

/// Círculo com as iniciais, numa cor fixa por pessoa (calculada pelo nome).
class AvatarMembro extends StatelessWidget {
  const AvatarMembro(this.membro, {super.key, this.raio = 22});

  final Membro membro;
  final double raio;

  static const _cores = [
    Color(0xFF8C9EFF),
    Color(0xFF4DD0E1),
    Color(0xFFFFB74D),
    Color(0xFFF48FB1),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
    Color(0xFF4FC3F7),
    Color(0xFFFF8A65),
  ];

  /// Soma dos códigos das letras: o mesmo nome sempre dá a mesma cor.
  Color get _cor => _cores[membro.nome.codeUnits.fold<int>(0, (s, c) => s + c) % _cores.length];

  @override
  Widget build(BuildContext context) {
    final cor = _cor;
    return CircleAvatar(
      radius: raio,
      backgroundColor: cor.withValues(alpha: 0.18),
      foregroundColor: cor,
      child: Text(
        membro.iniciais,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: raio * 0.68, letterSpacing: 0.3),
      ),
    );
  }
}
