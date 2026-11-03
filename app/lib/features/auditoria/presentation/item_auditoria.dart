import 'package:flutter/material.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../domain/registro_auditoria.dart';

/// Uma linha do histórico: ação, quem fez, quando e a justificativa.
class ItemAuditoria extends StatelessWidget {
  const ItemAuditoria(this.registro, {super.key, this.mostrarDescricao = true});

  final RegistroAuditoria registro;

  /// No histórico de um membro, a descrição repete o nome dele; lá ela só
  /// aparece para pagamentos, que trazem valores e datas.
  final bool mostrarDescricao;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final r = registro;
    final hora = '${r.dataHora.hour.toString().padLeft(2, '0')}:${r.dataHora.minute.toString().padLeft(2, '0')}';
    final descricao = mostrarDescricao || r.acao == AcaoAuditoria.liberacaoCiclo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Cores.lilas.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(r.acao.icone, size: 20, color: Cores.primaria),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.acao.rotulo, style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: Cores.tinta)),
                if (descricao) Text(r.descricao, style: texto.bodyMedium?.copyWith(color: Cores.tinta)),
                if (r.justificativa != null)
                  Text('Motivo: ${r.justificativa}', style: texto.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                Text(
                  '${Datas.formatar(r.dataHora)} às $hora · ${r.administradorNome}',
                  style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
