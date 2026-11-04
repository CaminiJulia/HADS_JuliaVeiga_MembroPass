import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cores.dart';

/// Tema escuro das áreas internas. As telas de entrada (`visual_entrada.dart`)
/// usam a mesma paleta, com fundo em degradê.
ThemeData criarTema() {
  final esquema = ColorScheme.fromSeed(seedColor: Cores.marca, brightness: Brightness.dark).copyWith(
    primary: Cores.primaria,
    onPrimary: Cores.noPrimaria,
    secondary: Cores.lilas,
    onSecondary: Cores.noPrimaria,
    surface: Cores.superficie,
    surfaceContainerHigh: Cores.superficieElevada,
    onSurface: Cores.tinta,
    onSurfaceVariant: Cores.textoSecundario,
    outline: Cores.borda,
    outlineVariant: Cores.borda,
    error: Cores.erro,
    onError: Cores.noPrimaria,
  );

  final raio12 = BorderRadius.circular(12);
  final bordaCampo = OutlineInputBorder(
    borderRadius: raio12,
    borderSide: const BorderSide(color: Cores.borda),
  );

  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: esquema);
  final texto = base.textTheme
      .apply(bodyColor: Cores.tinta, displayColor: Cores.tinta)
      .copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
        bodySmall: base.textTheme.bodySmall?.copyWith(color: Cores.textoSecundario),
      );

  return base.copyWith(
    scaffoldBackgroundColor: Cores.fundo,
    textTheme: texto,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Cores.fundo,
      foregroundColor: Cores.tinta,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      centerTitle: false,
      titleSpacing: 4,
      titleTextStyle: texto.titleLarge?.copyWith(fontSize: 20),
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: bordaCampo,
      enabledBorder: bordaCampo,
      focusedBorder: bordaCampo.copyWith(borderSide: const BorderSide(color: Cores.primaria, width: 2)),
      errorBorder: bordaCampo.copyWith(borderSide: const BorderSide(color: Cores.erro)),
      focusedErrorBorder: bordaCampo.copyWith(borderSide: const BorderSide(color: Cores.erro, width: 2)),
      disabledBorder: bordaCampo.copyWith(borderSide: BorderSide(color: Cores.borda.withValues(alpha: 0.6))),
      prefixIconColor: Cores.textoSecundario,
      suffixIconColor: Cores.textoSecundario,
      labelStyle: const TextStyle(color: Cores.textoSecundario),
      hintStyle: TextStyle(color: Cores.textoSecundario.withValues(alpha: 0.7)),
      helperStyle: const TextStyle(color: Cores.textoSecundario),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: raio12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: Cores.primaria,
        side: const BorderSide(color: Cores.borda),
        shape: RoundedRectangleBorder(borderRadius: raio12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Cores.primaria,
        shape: RoundedRectangleBorder(borderRadius: raio12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Cores.primaria,
      foregroundColor: Cores.noPrimaria,
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Cores.superficie,
      selectedColor: Cores.primaria.withValues(alpha: 0.2),
      checkmarkColor: Cores.primaria,
      side: const BorderSide(color: Cores.borda),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(color: Cores.tinta, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: Cores.primaria, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: Cores.superficie,
        selectedBackgroundColor: Cores.primaria.withValues(alpha: 0.2),
        selectedForegroundColor: Cores.primaria,
        side: const BorderSide(color: Cores.borda),
        shape: RoundedRectangleBorder(borderRadius: raio12),
        minimumSize: const Size(0, 46),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Cores.superficieElevada,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Cores.tinta, height: 1.3),
      contentTextStyle: texto.bodyMedium?.copyWith(color: Cores.textoSecundario, height: 1.4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Cores.superficieElevada,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: raio12),
      textStyle: texto.bodyLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Cores.superficieElevada,
      contentTextStyle: const TextStyle(color: Cores.tinta, fontSize: 14, height: 1.3),
      actionTextColor: Cores.lilas,
      shape: RoundedRectangleBorder(
        borderRadius: raio12,
        side: const BorderSide(color: Cores.borda),
      ),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Cores.superficieElevada,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dividerTheme: const DividerThemeData(color: Cores.borda, thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Cores.primaria),
    listTileTheme: const ListTileThemeData(iconColor: Cores.textoSecundario),
  );
}
