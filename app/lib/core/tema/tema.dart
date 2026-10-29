import 'package:flutter/material.dart';

import 'cores.dart';

ThemeData criarTema() {
  final esquema = ColorScheme.fromSeed(seedColor: Cores.primaria).copyWith(
    primary: Cores.primaria,
    onPrimary: Colors.white,
    secondary: Cores.lilas,
    surface: Cores.superficie,
    onSurface: Cores.tinta,
    error: Cores.erro,
  );

  final bordaCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Cores.borda),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Cores.fundo,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: bordaCampo,
      enabledBorder: bordaCampo,
      focusedBorder: bordaCampo.copyWith(
        borderSide: const BorderSide(color: Cores.primaria, width: 2),
      ),
      errorBorder: bordaCampo.copyWith(
        borderSide: const BorderSide(color: Cores.erro),
      ),
      focusedErrorBorder: bordaCampo.copyWith(
        borderSide: const BorderSide(color: Cores.erro, width: 2),
      ),
      prefixIconColor: Cores.textoSecundario,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Cores.primaria,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
