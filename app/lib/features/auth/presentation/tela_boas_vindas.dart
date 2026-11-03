import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/rotas.dart';
import '../../../core/tema/cores.dart';
import 'widgets/visual_entrada.dart';

/// Primeira tela do app, antes do login.
class TelaBoasVindas extends StatelessWidget {
  const TelaBoasVindas({super.key});

  @override
  Widget build(BuildContext context) {
    return FundoEntrada(
      child: Builder(
        // Builder para ler o tema escuro aplicado pelo FundoEntrada.
        builder: (context) {
          final texto = Theme.of(context).textTheme;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: NomeMarca(tamanho: 20)),
                    const Expanded(child: _Ilustracao()),
                    Text(
                      'Boas-vindas!',
                      textAlign: TextAlign.center,
                      style: texto.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sua carteirinha digital sempre no bolso.\nMostre o QR Code e pronto.',
                      textAlign: TextAlign.center,
                      style: texto.bodyLarge?.copyWith(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 36),
                    FilledButton.icon(
                      key: const Key('botao-entrar-com-email'),
                      onPressed: () => Navigator.of(context).pushNamed(Rotas.login),
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Entrar com e-mail'),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Ainda não tem acesso? Peça o link de adesão à sua organização.',
                      textAlign: TextAlign.center,
                      style: texto.bodySmall?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ícone da marca em destaque, levemente inclinado, com brilho e pixels de QR em volta.
class _Ilustracao extends StatelessWidget {
  const _Ilustracao();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, espaco) {
        final lado = (espaco.biggest.shortestSide * 0.62).clamp(96.0, 220.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            PixelsQr(tamanho: Size(lado * 1.9, lado * 1.6), canto: Alignment.center, semente: 11),
            Container(
              width: lado,
              height: lado,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Cores.marca.withValues(alpha: 0.7), blurRadius: lado * 0.6)],
              ),
            ),
            Transform.rotate(
              angle: -0.12,
              child: SvgPicture.asset('assets/marca/icone.svg', width: lado, excludeFromSemantics: true),
            ),
          ],
        );
      },
    );
  }
}
