import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Carteirinha de exemplo com a marca da organização, para a pré-visualização (RF17).
class PreviaCarteirinha extends StatelessWidget {
  const PreviaCarteirinha({super.key, required this.cor, required this.nomeOrganizacao, this.logo});

  final Color cor;
  final String nomeOrganizacao;
  final Uint8List? logo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final escura = Color.lerp(cor, Colors.black, 0.35)!;

    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cor, escura]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: logo == null
                      ? Icon(Icons.shield_outlined, color: cor)
                      : Image.memory(logo!, fit: BoxFit.contain, semanticLabel: 'Logo da organização'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nomeOrganizacao,
                    overflow: TextOverflow.ellipsis,
                    style: texto.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marina Membro',
                          style: texto.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      Text('Plano Mensal · Válida até 23/11/2026',
                          style: texto.bodySmall?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.qr_code_2, size: 52, color: escura),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
