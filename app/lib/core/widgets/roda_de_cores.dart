import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../tema/contraste.dart';
import '../tema/cores.dart';

/// Resultado da avaliação de uma cor na roda: se pode ser usada e o porquê.
typedef AvaliacaoCor = ({bool ok, String mensagem});

/// Abre a roda de cores. Devolve "#RRGGBB" ou `null` se o administrador
/// cancelar. [avaliar] diz se a cor serve para o uso (contraste etc.); o
/// botão "Usar cor" só fica habilitado quando ela serve.
Future<String?> escolherNaRodaDeCores(
  BuildContext context, {
  required Color inicial,
  required AvaliacaoCor Function(Color) avaliar,
  String titulo = 'Cor personalizada',
}) {
  return showDialog<String>(context: context, builder: (_) => _DialogoRodaDeCores(inicial, avaliar, titulo));
}

class _DialogoRodaDeCores extends StatefulWidget {
  const _DialogoRodaDeCores(this.inicial, this.avaliar, this.titulo);

  final Color inicial;
  final AvaliacaoCor Function(Color) avaliar;
  final String titulo;

  @override
  State<_DialogoRodaDeCores> createState() => _DialogoRodaDeCoresState();
}

class _DialogoRodaDeCoresState extends State<_DialogoRodaDeCores> {
  late Color _cor = widget.inicial;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final avaliacao = widget.avaliar(_cor);
    final hex = Contraste.paraHex(_cor);

    return AlertDialog(
      title: Text(widget.titulo),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorPicker(
              pickerColor: _cor,
              onColorChanged: (c) => setState(() => _cor = c.withValues(alpha: 1)),
              paletteType: PaletteType.hueWheel,
              enableAlpha: false,
              labelTypes: const [],
              displayThumbColor: true,
              colorPickerWidth: 240,
              portraitOnly: true,
            ),
            // A roda já mostra a cor escolhida ao lado da barra de brilho;
            // aqui ficam o código e se ela serve para o uso.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    avaliacao.ok ? Icons.check_circle_outline : Icons.error_outline,
                    size: 20,
                    color: avaliacao.ok ? Cores.sucesso : Cores.erro,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hex, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          avaliacao.mensagem,
                          key: const Key('aviso-cor-personalizada'),
                          style: texto.bodySmall?.copyWith(color: avaliacao.ok ? Cores.sucesso : Cores.erro),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('botao-usar-cor'),
          onPressed: avaliacao.ok ? () => Navigator.pop(context, hex) : null,
          child: const Text('Usar cor'),
        ),
      ],
    );
  }
}

/// Anel de arco-íris que abre a roda de cores; com [cor], mostra no meio a
/// cor personalizada já escolhida.
class AnelArcoIris extends StatelessWidget {
  const AnelArcoIris(this.cor, {super.key});

  final Color? cor;

  static const _espectro = SweepGradient(
    colors: [
      Color(0xFFFF5252),
      Color(0xFFFFD740),
      Color(0xFF69F0AE),
      Color(0xFF40C4FF),
      Color(0xFF7C4DFF),
      Color(0xFFFF4081),
      Color(0xFFFF5252),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _espectro),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: cor ?? Cores.fundo),
        child: Icon(cor == null ? Icons.colorize : Icons.check, size: 15, color: Colors.white),
      ),
    );
  }
}
