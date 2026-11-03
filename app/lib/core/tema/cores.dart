import 'package:flutter/material.dart';

/// Paleta do MembroPass no tema escuro (modelo padrão da plataforma, RF17).
/// Os nomes indicam o papel da cor, não o tom: [tinta] é o texto principal
/// (claro) e [fundo] é o fundo das telas (escuro).
abstract final class Cores {
  /// Azul da marca: fundo de cabeçalhos e carteirinhas, sempre com texto branco.
  static const marca = Color(0xFF2B2FB8);
  static const marcaEscura = Color(0xFF1C1F5C);

  /// Destaque das áreas escuras: botões, links, ícones e seleção.
  static const primaria = Color(0xFFA7A9F5);

  /// Texto e ícones em cima de [primaria].
  static const noPrimaria = Color(0xFF14163A);
  static const lilas = Color(0xFFA7A9F5);

  static const fundo = Color(0xFF0E1030);
  static const superficie = Color(0xFF171A42);
  static const superficieElevada = Color(0xFF20244F);
  static const borda = Color(0xFF2E3266);

  static const tinta = Color(0xFFECEDFF);
  static const textoSecundario = Color(0xFFA4A7CC);

  static const erro = Color(0xFFFF8A80);
  static const erroFundo = Color(0xFF3A1A24);

  static const sucesso = Color(0xFF6EDC9F);
  static const sucessoFundo = Color(0xFF14392A);
  static const alerta = Color(0xFFFFC266);
  static const alertaFundo = Color(0xFF3B2E12);
}
