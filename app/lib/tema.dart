import 'package:flutter/material.dart';

/// Cores da marca MembroPass, tiradas do logotipo.
abstract final class CoresMarca {
  static const azul = Color(0xFF2B2FB8);
  static const azulEscuro = Color(0xFF14163A);
  static const lilas = Color(0xFFA7A9F5);
  static const fundo = Color(0xFFF6F6FB);
}

ThemeData criarTema() {
  final esquema = ColorScheme.fromSeed(
    seedColor: CoresMarca.azul,
    primary: CoresMarca.azul,
    onSurface: CoresMarca.azulEscuro,
    surface: Colors.white,
  );

  final bordaCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey.shade300),
  );

  return ThemeData(
    colorScheme: esquema,
    scaffoldBackgroundColor: CoresMarca.fundo,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: bordaCampo,
      enabledBorder: bordaCampo,
      focusedBorder: bordaCampo.copyWith(
        borderSide: const BorderSide(color: CoresMarca.azul, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
