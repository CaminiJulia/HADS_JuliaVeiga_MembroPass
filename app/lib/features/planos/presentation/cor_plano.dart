import 'package:flutter/material.dart';

import '../../../core/tema/contraste.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/roda_de_cores.dart';
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
                  final escolhida = await escolherNaRodaDeCores(
                    context,
                    inicial: corDoPlano(selecionada),
                    avaliar: (c) => corEscuraDemais(c)
                        ? (ok: false, mensagem: 'Escura demais: sumiria no fundo escuro do app.')
                        : (ok: true, mensagem: 'Boa para destacar o plano.'),
                  );
                  if (escolhida != null) aoEscolher(escolhida);
                }
              : null,
          child: AnelArcoIris(personalizada ? corDoPlano(hex) : null),
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
  const _Interior.cheia(Color this.cor, {this.marcada = false}) : icone = null;

  /// Só o contorno, com um ícone: a amostra "padrão".
  const _Interior.contorno(Color this.cor, this.icone) : marcada = false;

  final Color? cor;
  final IconData? icone;
  final bool marcada;

  @override
  Widget build(BuildContext context) {
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
