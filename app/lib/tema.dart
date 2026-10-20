import 'package:flutter/material.dart';

// Cor do modelo neutro, usada enquanto a organização não configura a sua (RF17).
const corPadrao = Color(0xFF334155);

// Converte "#RRGGBB" (formato de organizacao.cor_principal) em Color.
Color? corDeHex(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

// Tema do app a partir da cor principal da organização (white-label).
ThemeData temaDaOrganizacao(String? corPrincipal) {
  final esquema = ColorScheme.fromSeed(seedColor: corDeHex(corPrincipal) ?? corPadrao);
  return ThemeData(
    colorScheme: esquema,
    useMaterial3: true,
    appBarTheme: AppBarTheme(backgroundColor: esquema.primary, foregroundColor: esquema.onPrimary),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
