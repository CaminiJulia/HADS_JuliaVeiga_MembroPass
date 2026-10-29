import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tema.dart';
import 'visual_entrada.dart';

/// Primeira tela do app, antes do login.
class TelaBoasVindas extends StatelessWidget {
  const TelaBoasVindas({super.key, required this.aoEntrarComEmail});

  final VoidCallback aoEntrarComEmail;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return FundoEntrada(
      child: Center(
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
                  style: textos.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sua carteirinha digital sempre no bolso.\nMostre o QR Code e pronto.',
                  textAlign: TextAlign.center,
                  style: textos.bodyLarge?.copyWith(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 36),
                FilledButton.icon(
                  key: const Key('botao-entrar-com-email'),
                  onPressed: aoEntrarComEmail,
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Entrar com e-mail'),
                ),
                const SizedBox(height: 18),
                Text(
                  'Ainda não tem conta? Fale com a sua organização.',
                  textAlign: TextAlign.center,
                  style: textos.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
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
                boxShadow: [BoxShadow(color: CoresMarca.azul.withValues(alpha: 0.7), blurRadius: lado * 0.6)],
              ),
            ),
            Transform.rotate(
              angle: -0.12,
              child: SvgPicture.asset('assets/marca/membropass-icone.svg', width: lado, excludeFromSemantics: true),
            ),
          ],
        );
      },
    );
  }
}
