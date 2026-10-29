import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema.dart';

/// Visual escuro compartilhado pelas telas de entrada (boas-vindas e login).
ThemeData criarTemaEntrada() {
  final esquema = ColorScheme.fromSeed(seedColor: CoresMarca.azul, brightness: Brightness.dark).copyWith(
    primary: CoresMarca.lilas,
    onPrimary: CoresMarca.azulEscuro,
    surface: CoresMarca.azulEscuro,
    onSurface: Colors.white,
  );

  UnderlineInputBorder linha(Color cor, [double espessura = 1]) =>
      UnderlineInputBorder(borderSide: BorderSide(color: cor, width: espessura));

  return ThemeData(
    colorScheme: esquema,
    scaffoldBackgroundColor: CoresMarca.azulEscuro,
    textSelectionTheme: const TextSelectionThemeData(cursorColor: CoresMarca.lilas),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: Colors.white70),
      floatingLabelStyle: const TextStyle(color: CoresMarca.lilas),
      prefixIconColor: Colors.white70,
      suffixIconColor: Colors.white70,
      border: linha(Colors.white30),
      enabledBorder: linha(Colors.white30),
      focusedBorder: linha(CoresMarca.lilas, 2),
      errorBorder: linha(esquema.error),
      focusedErrorBorder: linha(esquema.error, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CoresMarca.lilas,
        foregroundColor: CoresMarca.azulEscuro,
        disabledBackgroundColor: CoresMarca.lilas.withValues(alpha: 0.5),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: CoresMarca.lilas)),
  );
}

/// Fundo das telas de entrada: degradê da marca com "pixels" de QR Code
/// nos cantos, no lugar das ilustrações decorativas.
class FundoEntrada extends StatelessWidget {
  const FundoEntrada({super.key, required this.child, this.comVoltar = false});

  final Widget child;
  final bool comVoltar;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: criarTemaEntrada(),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: comVoltar
              ? AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0)
              : null,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1C1F5C), CoresMarca.azulEscuro],
              ),
            ),
            child: Stack(
              children: [
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: PixelsQr(tamanho: Size(200, 130), canto: Alignment.bottomRight, semente: 7),
                ),
                const Positioned(
                  left: 0,
                  bottom: 0,
                  child: PixelsQr(tamanho: Size(110, 90), canto: Alignment.bottomLeft, semente: 3),
                ),
                SafeArea(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quadradinhos no estilo do QR Code do logotipo, mais densos e fortes
/// perto do [canto] e sumindo conforme se afastam dele.
class PixelsQr extends StatelessWidget {
  const PixelsQr({super.key, required this.tamanho, required this.canto, this.semente = 1});

  final Size tamanho;
  final Alignment canto;
  final int semente;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(size: tamanho, painter: _PintorPixels(canto, semente)),
    );
  }
}

class _PintorPixels extends CustomPainter {
  _PintorPixels(this.canto, this.semente);

  final Alignment canto;
  final int semente;

  static const _passo = 22.0;
  static const _lado = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Semente fixa: o desenho é sempre o mesmo, não "pisca" a cada rebuild.
    final sorteio = Random(semente);
    final origem = canto.alongSize(size);
    // Some por completo no ponto mais distante da origem, sem deixar borda reta.
    final alcance = [Offset.zero, size.topRight(Offset.zero), size.bottomLeft(Offset.zero), size.bottomRight(Offset.zero)]
        .map((c) => (c - origem).distance)
        .reduce(max);
    final pincel = Paint();

    for (var x = 0.0; x + _lado <= size.width; x += _passo) {
      for (var y = 0.0; y + _lado <= size.height; y += _passo) {
        final centro = Offset(x + _lado / 2, y + _lado / 2);
        final proximidade = 1 - ((centro - origem).distance / alcance).clamp(0.0, 1.0);
        if (sorteio.nextDouble() > proximidade * 0.85) continue;

        pincel.color = CoresMarca.lilas.withValues(alpha: 0.03 + proximidade * 0.17);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, _lado, _lado), const Radius.circular(4)),
          pincel,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PintorPixels antigo) => antigo.canto != canto || antigo.semente != semente;
}

/// Nome da marca em texto, com "Pass" em lilás como no logotipo para fundo escuro.
class NomeMarca extends StatelessWidget {
  const NomeMarca({super.key, this.tamanho = 22});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(fontSize: tamanho, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.white);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Membro', style: estilo),
          TextSpan(text: 'Pass', style: estilo.copyWith(color: CoresMarca.lilas)),
        ],
      ),
      semanticsLabel: 'MembroPass',
    );
  }
}
