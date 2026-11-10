import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/tema/cores.dart';

/// Logo do parceiro num quadrado branco (como nos apps de cupons). Sem logo,
/// mostra as iniciais do parceiro no degradê da marca.
class LogoParceiro extends StatelessWidget {
  const LogoParceiro({super.key, required this.logo, required this.iniciais, this.tamanho = 64});

  final Uint8List? logo;
  final String iniciais;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(tamanho * 0.22);
    if (logo != null) {
      return Container(
        width: tamanho,
        height: tamanho,
        padding: EdgeInsets.all(tamanho * 0.1),
        decoration: BoxDecoration(color: Colors.white, borderRadius: raio),
        child: Image.memory(
          logo!,
          fit: BoxFit.contain,
          semanticLabel: 'Logo do parceiro',
          errorBuilder: (_, _, _) => const Icon(Icons.storefront_outlined, color: Cores.marca),
        ),
      );
    }
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Cores.marca, Cores.marcaEscura],
        ),
        borderRadius: raio,
      ),
      child: Text(
        iniciais,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: tamanho * 0.34,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
