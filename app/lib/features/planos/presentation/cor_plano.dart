import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../core/tema/contraste.dart';
import '../../../core/tema/cores.dart';
import '../domain/plano.dart';

/// Cores sugeridas para os planos: tons médios, que aparecem bem tanto como
/// destaque no fundo escuro quanto escurecidos, com texto branco, na prévia.
const paletaPlanos = ['#3A9FE0', '#9C6ADE', '#E0A030', '#2BB5A0', '#E05A8A', '#4CAF50', '#E2703A', '#6C72F5'];

/// Contraste mínimo de uma cor de plano com o fundo do app: abaixo disso,
/// faixas, ícones e pontos ficariam invisíveis (3:1, o mínimo da WCAG para
/// elementos gráficos).
const contrasteMinimoComFundo = 3.0;

/// Cor do plano para usar na tela; sem cor definida, usa o destaque padrão.
Color corDoPlano(String? hex) => (hex == null ? null : Contraste.lerHex(hex)) ?? Cores.primaria;

/// Degradê de fundo com a cor do plano, escurecida o bastante para texto branco.
List<Color> degradeDoPlano(String? hex) {
  if (hex == null) return const [Cores.marca, Cores.marcaEscura];
  final cor = corDoPlano(hex);
  final inicio = Contraste.escurecerParaBranco(cor);
  return [inicio, Color.lerp(inicio, Colors.black, 0.45)!];
}

/// Cor escura demais para aparecer no fundo escuro do app?
bool corEscuraDemais(Color cor) => Contraste.entre(cor, Cores.fundo) < contrasteMinimoComFundo;

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

/// Escolha da cor do plano: a padrão (`null`), uma das sugeridas ou qualquer
/// outra pela roda de cores (bolinha com arco-íris).
class SeletorCorPlano extends StatelessWidget {
  const SeletorCorPlano({super.key, required this.selecionada, required this.aoEscolher, this.habilitado = true});

  final String? selecionada;
  final ValueChanged<String?> aoEscolher;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final hex = selecionada?.toUpperCase();
    final personalizada = hex != null && !paletaPlanos.contains(hex);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Amostra(
          rotulo: 'Cor padrão',
          selecionada: hex == null,
          aoTocar: habilitado ? () => aoEscolher(null) : null,
          child: const _Interior.contorno(Cores.primaria, Icons.auto_awesome),
        ),
        for (final cor in paletaPlanos)
          _Amostra(
            rotulo: 'Cor $cor',
            selecionada: hex == cor,
            aoTocar: habilitado ? () => aoEscolher(cor) : null,
            child: _Interior.cheia(corDoPlano(cor), marcada: hex == cor),
          ),
        _Amostra(
          rotulo: 'Cor personalizada',
          selecionada: personalizada,
          aoTocar: habilitado
              ? () async {
                  final escolhida = await escolherCorPersonalizada(context, inicial: corDoPlano(selecionada));
                  if (escolhida != null) aoEscolher(escolhida);
                }
              : null,
          child: _Interior.arcoIris(personalizada ? corDoPlano(hex) : null),
        ),
      ],
    );
  }
}

/// Abre a roda de cores. Devolve "#RRGGBB" ou `null` se o administrador cancelar.
Future<String?> escolherCorPersonalizada(BuildContext context, {required Color inicial}) {
  return showDialog<String>(context: context, builder: (_) => _DialogoRodaDeCores(inicial));
}

class _DialogoRodaDeCores extends StatefulWidget {
  const _DialogoRodaDeCores(this.inicial);

  final Color inicial;

  @override
  State<_DialogoRodaDeCores> createState() => _DialogoRodaDeCoresState();
}

class _DialogoRodaDeCoresState extends State<_DialogoRodaDeCores> {
  late Color _cor = widget.inicial;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final escura = corEscuraDemais(_cor);
    final hex = Contraste.paraHex(_cor);

    return AlertDialog(
      title: const Text('Cor personalizada'),
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
            // aqui ficam o código e se ela serve para o fundo escuro.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    escura ? Icons.error_outline : Icons.check_circle_outline,
                    size: 20,
                    color: escura ? Cores.erro : Cores.sucesso,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hex, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          escura ? 'Escura demais: sumiria no fundo escuro do app.' : 'Boa para destacar o plano.',
                          key: const Key('aviso-cor-personalizada'),
                          style: texto.bodySmall?.copyWith(color: escura ? Cores.erro : Cores.sucesso),
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
          onPressed: escura ? null : () => Navigator.pop(context, hex),
          child: const Text('Usar cor'),
        ),
      ],
    );
  }
}

class _Amostra extends StatelessWidget {
  const _Amostra({required this.rotulo, required this.selecionada, required this.aoTocar, required this.child});

  final String rotulo;
  final bool selecionada;
  final VoidCallback? aoTocar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionada,
      label: rotulo,
      excludeSemantics: true,
      child: Tooltip(
        message: rotulo,
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
            child: child,
          ),
        ),
      ),
    );
  }
}

/// O círculo de dentro de cada amostra.
class _Interior extends StatelessWidget {
  const _Interior.cheia(Color this.cor, {this.marcada = false}) : icone = null, arcoIris = false;

  /// Só o contorno, com um ícone: a amostra "padrão".
  const _Interior.contorno(Color this.cor, this.icone) : marcada = false, arcoIris = false;

  /// Anel de arco-íris; com [cor], mostra a cor personalizada escolhida.
  const _Interior.arcoIris(this.cor) : marcada = false, icone = null, arcoIris = true;

  final Color? cor;
  final IconData? icone;
  final bool marcada;
  final bool arcoIris;

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
    if (arcoIris) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _espectro),
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: cor ?? Cores.fundo),
          child: Icon(cor == null ? Icons.colorize : Icons.check, size: 15, color: Colors.white),
        ),
      );
    }
    if (icone != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cor!, width: 2),
        ),
        child: Icon(icone, size: 14, color: cor),
      );
    }
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
      child: marcada ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
    );
  }
}

/// Etiqueta com o nome do plano e o ponto na cor dele, para listas de planos
/// aceitos ou com direito.
class EtiquetaPlano extends StatelessWidget {
  const EtiquetaPlano(this.plano, {super.key});

  final Plano plano;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Cores.fundo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Cores.borda),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PontoCorPlano(plano.cor, tamanho: 7),
          const SizedBox(width: 5),
          Text(plano.nome, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Cores.tinta)),
        ],
      ),
    );
  }
}
