import 'package:flutter/material.dart';

import '../../../core/tema/contraste.dart';
import '../../../core/tema/cores.dart';

/// Cores disponíveis para os planos: tons médios, que aparecem bem tanto como
/// destaque no fundo escuro quanto escurecidos, com texto branco, na prévia.
const paletaPlanos = ['#3A9FE0', '#9C6ADE', '#E0A030', '#2BB5A0', '#E05A8A', '#4CAF50', '#E2703A', '#6C72F5'];

/// Cor do plano para usar na tela; sem cor definida, usa o destaque padrão.
Color corDoPlano(String? hex) => (hex == null ? null : Contraste.lerHex(hex)) ?? Cores.primaria;

/// Bolinha com a cor do plano, para listas.
class PontoCorPlano extends StatelessWidget {
  const PontoCorPlano(this.hex, {super.key, this.tamanho = 8});

  final String? hex;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(color: corDoPlano(hex), shape: BoxShape.circle),
    );
  }
}

/// Escolha da cor do plano entre as da [paletaPlanos], ou a padrão (`null`).
class SeletorCorPlano extends StatelessWidget {
  const SeletorCorPlano({super.key, required this.selecionada, required this.aoEscolher, this.habilitado = true});

  final String? selecionada;
  final ValueChanged<String?> aoEscolher;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Amostra(
          rotulo: 'Cor padrão',
          cor: Cores.primaria,
          selecionada: selecionada == null,
          padrao: true,
          aoTocar: habilitado ? () => aoEscolher(null) : null,
        ),
        for (final hex in paletaPlanos)
          _Amostra(
            rotulo: 'Cor $hex',
            cor: corDoPlano(hex),
            selecionada: selecionada?.toUpperCase() == hex,
            aoTocar: habilitado ? () => aoEscolher(hex) : null,
          ),
      ],
    );
  }
}

class _Amostra extends StatelessWidget {
  const _Amostra({
    required this.rotulo,
    required this.cor,
    required this.selecionada,
    required this.aoTocar,
    this.padrao = false,
  });

  final String rotulo;
  final Color cor;
  final bool selecionada;
  final VoidCallback? aoTocar;

  /// A amostra "padrão" é só um contorno, para diferenciar das cores escolhidas.
  final bool padrao;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionada,
      label: rotulo,
      excludeSemantics: true,
      child: InkWell(
        onTap: aoTocar,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selecionada ? Cores.tinta : Colors.transparent, width: 2),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: padrao ? Colors.transparent : cor,
              border: padrao ? Border.all(color: cor, width: 2) : null,
            ),
            child: selecionada
                ? Icon(Icons.check, size: 18, color: padrao ? cor : Colors.white)
                : padrao
                ? Icon(Icons.auto_awesome, size: 14, color: cor)
                : null,
          ),
        ),
      ),
    );
  }
}
