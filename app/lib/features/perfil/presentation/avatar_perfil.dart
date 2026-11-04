import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/tema/cores.dart';

/// Foto redonda do usuário; sem foto, mostra as iniciais sobre a cor da marca.
class AvatarPerfil extends StatelessWidget {
  const AvatarPerfil({super.key, required this.iniciais, this.foto, this.tamanho = 40, this.borda = false});

  final String iniciais;
  final Uint8List? foto;
  final double tamanho;

  /// Anel claro em volta, para destacar o avatar sobre fundos coloridos.
  final bool borda;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Cores.lilas, Cores.marca],
        ),
        border: borda ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: tamanho * 0.035 + 1) : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: foto != null
          ? Image.memory(foto!, fit: BoxFit.cover, width: tamanho, height: tamanho, gaplessPlayback: true)
          : Text(
              iniciais,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: tamanho * 0.36,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
