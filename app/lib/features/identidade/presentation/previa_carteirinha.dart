import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/organizacao.dart';

/// Carteirinha de exemplo com a marca da organização (RF17): cores, estilo
/// do fundo e modelo do layout. Com [esboco], vira uma miniatura sem textos
/// (barrinhas no lugar das palavras), para o seletor de modelos.
class PreviaCarteirinha extends StatelessWidget {
  const PreviaCarteirinha({
    super.key,
    required this.cor,
    required this.nomeOrganizacao,
    this.corSecundaria,
    this.estilo = EstiloFundo.degrade,
    this.modelo = ModeloCarteirinha.classico,
    this.logo,
    this.esboco = false,
  });

  final Color cor;

  /// Segunda cor do degradê; `null` usa uma versão escura de [cor].
  final Color? corSecundaria;
  final String nomeOrganizacao;
  final EstiloFundo estilo;
  final ModeloCarteirinha modelo;
  final Uint8List? logo;
  final bool esboco;

  Color get _segunda => corSecundaria ?? Color.lerp(cor, Colors.black, 0.35)!;

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(20);
    final cartao = AspectRatio(
      aspectRatio: 1.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cor,
          gradient: estilo == EstiloFundo.degrade
              ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cor, _segunda])
              : null,
          borderRadius: raio,
          boxShadow: esboco
              ? null
              : [BoxShadow(color: cor.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: raio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (estilo == EstiloFundo.padrao) CustomPaint(painter: _PintorPadrao()),
              Padding(
                padding: const EdgeInsets.all(18),
                child: switch (modelo) {
                  ModeloCarteirinha.classico => _Classico(this),
                  ModeloCarteirinha.moderno => _Moderno(this),
                  ModeloCarteirinha.minimalista => _Minimalista(this),
                },
              ),
            ],
          ),
        ),
      ),
    );
    // A miniatura é a carteirinha em tamanho real, só reduzida: mesmas proporções.
    return esboco ? FittedBox(child: SizedBox(width: 340, child: cartao)) : cartao;
  }
}

/// Logo em cima à esquerda; nome e plano embaixo; QR pequeno no canto.
class _Classico extends StatelessWidget {
  const _Classico(this.c);

  final PreviaCarteirinha c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Logo(c, tamanho: 40),
            SizedBox(width: 10),
            Expanded(child: _Texto(c, c.nomeOrganizacao, _Papel.organizacao)),
          ],
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Texto(c, 'Marina Membro', _Papel.nome),
                  _Texto(c, 'Plano Mensal · Válida até 23/11/2026', _Papel.detalhe),
                ],
              ),
            ),
            _Qr(c, tamanho: 60),
          ],
        ),
      ],
    );
  }
}

/// Informações à esquerda e um QR Code grande à direita, fácil de ler.
class _Moderno extends StatelessWidget {
  const _Moderno(this.c);

  final PreviaCarteirinha c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(c, tamanho: 36),
              SizedBox(height: 8),
              _Texto(c, c.nomeOrganizacao, _Papel.organizacao),
              const Spacer(),
              _Texto(c, 'Marina Membro', _Papel.nome),
              _Texto(c, 'Plano Mensal', _Papel.detalhe),
              _Texto(c, 'Válida até 23/11/2026', _Papel.detalhe),
            ],
          ),
        ),
        SizedBox(width: 14),
        _Qr(c, tamanho: 112),
      ],
    );
  }
}

/// Tudo centralizado: marca, nome e um QR discreto.
class _Minimalista extends StatelessWidget {
  const _Minimalista(this.c);

  final PreviaCarteirinha c;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Logo(c, tamanho: 26),
            SizedBox(width: 8),
            Flexible(child: _Texto(c, c.nomeOrganizacao, _Papel.detalhe)),
          ],
        ),
        const Spacer(),
        _Texto(c, 'Marina Membro', _Papel.nome, centralizado: true),
        _Texto(c, 'Válida até 23/11/2026', _Papel.detalhe, centralizado: true),
        const Spacer(),
        _Qr(c, tamanho: 44),
      ],
    );
  }
}

enum _Papel { organizacao, nome, detalhe }

/// Texto da carteirinha; no esboço, uma barrinha do tamanho aproximado.
class _Texto extends StatelessWidget {
  const _Texto(this.c, this.texto, this.papel, {this.centralizado = false});

  final PreviaCarteirinha c;
  final String texto;
  final _Papel papel;
  final bool centralizado;

  @override
  Widget build(BuildContext context) {
    if (c.esboco) {
      final (largura, altura, opacidade) = switch (papel) {
        _Papel.organizacao => (130.0, 16.0, 0.9),
        _Papel.nome => (150.0, 18.0, 1.0),
        _Papel.detalhe => (110.0, 11.0, 0.6),
      };
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Container(
          width: largura,
          height: altura,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacidade),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }
    final estilos = Theme.of(context).textTheme;
    final estilo = switch (papel) {
      _Papel.organizacao => estilos.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
      _Papel.nome => estilos.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      _Papel.detalhe => estilos.bodySmall?.copyWith(color: Colors.white),
    };
    return Text(
      texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: centralizado ? TextAlign.center : null,
      style: estilo,
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo(this.c, {required this.tamanho});

  final PreviaCarteirinha c;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      padding: EdgeInsets.all(tamanho * 0.1),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(tamanho * 0.25)),
      child: c.esboco
          ? null
          : c.logo == null
          ? Icon(Icons.shield_outlined, color: c.cor, size: tamanho * 0.6)
          : Image.memory(c.logo!, fit: BoxFit.contain, semanticLabel: 'Logo da organização'),
    );
  }
}

class _Qr extends StatelessWidget {
  const _Qr(this.c, {required this.tamanho});

  final PreviaCarteirinha c;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      padding: EdgeInsets.all(tamanho * 0.07),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(tamanho * 0.14)),
      child: FittedBox(child: Icon(Icons.qr_code_2, color: c._segunda)),
    );
  }
}

/// Quadradinhos claros espalhados, lembrando o QR Code da marca.
class _PintorPadrao extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sorteio = Random(7); // semente fixa: o desenho não muda a cada quadro
    final passo = max(size.shortestSide / 9, 6.0);
    final lado = passo * 0.72;
    final pincel = Paint();
    for (var x = 0.0; x < size.width; x += passo) {
      for (var y = 0.0; y < size.height; y += passo) {
        // Mais denso no canto superior direito, sumindo para o outro lado.
        final peso = ((x / size.width) + (1 - y / size.height)) / 2;
        if (sorteio.nextDouble() > peso * 0.8) continue;
        pincel.color = Colors.white.withValues(alpha: 0.04 + peso * 0.1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, lado, lado), Radius.circular(lado * 0.25)),
          pincel,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PintorPadrao antigo) => false;
}
