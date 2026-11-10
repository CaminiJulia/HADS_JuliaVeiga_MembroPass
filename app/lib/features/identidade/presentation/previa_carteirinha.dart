import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../domain/organizacao.dart';

/// Dados de quem aparece na carteirinha. Sem eles, a prévia usa um exemplo.
class DadosCarteirinha {
  const DadosCarteirinha({
    required this.nomeMembro,
    required this.plano,
    required this.validade,
    this.numero,
    this.foto,
    this.qrCodigo,
    this.avisoQr,
  });

  static const exemplo = DadosCarteirinha(
    nomeMembro: 'Marina Membro',
    plano: 'Plano Mensal',
    validade: 'Válida até 23/11/2026',
    numero: '38F29DBA',
  );

  final String nomeMembro;
  final String plano;
  final String validade;
  final String? numero;
  final Uint8List? foto;

  /// Conteúdo do QR Code; `null` mostra só o símbolo (prévia do administrador).
  final String? qrCodigo;

  /// Quando há aviso (bloqueada, código expirado...), ele toma o lugar do QR.
  final String? avisoQr;
}

/// Carteirinha vertical com a marca da organização (RF17): cores, estilo do
/// fundo e modelo do layout. É a mesma na prévia do administrador e no app do
/// membro, onde ocupa quase a tela toda. Com [esboco], vira uma miniatura sem
/// textos, para o seletor de modelos.
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
    this.dados = DadosCarteirinha.exemplo,
    this.aoTocarFoto,
    this.aoTocarQr,
  });

  /// Proporção em pé (largura / altura), a de um crachá.
  static const proporcao = 0.625;

  /// Tamanho de desenho; na tela, o cartão é ampliado ou reduzido por inteiro.
  static const _largura = 320.0;
  static const _altura = _largura / proporcao;

  final Color cor;

  /// Segunda cor do degradê; `null` usa uma versão escura de [cor].
  final Color? corSecundaria;
  final String nomeOrganizacao;
  final EstiloFundo estilo;
  final ModeloCarteirinha modelo;
  final Uint8List? logo;
  final bool esboco;
  final DadosCarteirinha dados;

  /// No app do membro, tocar na foto abre a troca de foto.
  final VoidCallback? aoTocarFoto;

  /// No app do membro, tocar no QR Code abre ele ampliado.
  final VoidCallback? aoTocarQr;

  Color get _segunda => corSecundaria ?? Color.lerp(cor, Colors.black, 0.35)!;

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(24);
    final cartao = DecoratedBox(
      decoration: BoxDecoration(
        color: cor,
        gradient: estilo == EstiloFundo.degrade
            ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cor, _segunda])
            : null,
        borderRadius: raio,
        boxShadow: esboco
            ? null
            : [BoxShadow(color: cor.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: raio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (estilo == EstiloFundo.padrao) CustomPaint(painter: _PintorPadrao()),
            Padding(
              padding: const EdgeInsets.all(22),
              child: switch (modelo) {
                ModeloCarteirinha.classico => _Classico(this),
                ModeloCarteirinha.moderno => _Moderno(this),
                ModeloCarteirinha.minimalista => _Minimalista(this),
              },
            ),
          ],
        ),
      ),
    );
    // Desenhada sempre no mesmo tamanho e ampliada por inteiro: as proporções
    // não mudam entre a miniatura, a prévia e a tela do membro.
    return AspectRatio(
      aspectRatio: proporcao,
      child: FittedBox(
        child: SizedBox(width: _largura, height: _altura, child: cartao),
      ),
    );
  }
}

/// Marca em cima; foto redonda, nome e plano no centro; QR embaixo.
class _Classico extends StatelessWidget {
  const _Classico(this.c);

  final PreviaCarteirinha c;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _Logo(c, tamanho: 36),
            const SizedBox(width: 10),
            Expanded(child: _Texto(c, c.nomeOrganizacao, _Papel.organizacao)),
          ],
        ),
        const SizedBox(height: 18),
        _Foto(c, largura: 112, altura: 112, redonda: true),
        const SizedBox(height: 12),
        _Texto(c, c.dados.nomeMembro, _Papel.nome, centralizado: true),
        const SizedBox(height: 2),
        _Texto(c, '${c.dados.plano} · ${c.dados.validade}', _Papel.detalhe, centralizado: true),
        const Spacer(),
        _AreaQr(c, lado: 190),
        const SizedBox(height: 8),
        _Numero(c),
      ],
    );
  }
}

/// Foto e dados lado a lado; QR Code bem grande, ocupando a largura.
class _Moderno extends StatelessWidget {
  const _Moderno(this.c);

  final PreviaCarteirinha c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Logo(c, tamanho: 32),
            const SizedBox(width: 10),
            Expanded(child: _Texto(c, c.nomeOrganizacao, _Papel.organizacao)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _Foto(c, largura: 92, altura: 112, redonda: false),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Texto(c, c.dados.nomeMembro, _Papel.nome),
                  const SizedBox(height: 4),
                  _Texto(c, c.dados.plano, _Papel.detalhe),
                  _Texto(c, c.dados.validade, _Papel.detalhe),
                  const SizedBox(height: 6),
                  _Numero(c, centralizado: false),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        _AreaQr(c, lado: 276),
      ],
    );
  }
}

/// Tudo centralizado e enxuto: foto grande, nome e um QR discreto.
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
            _Logo(c, tamanho: 24),
            const SizedBox(width: 8),
            Flexible(child: _Texto(c, c.nomeOrganizacao, _Papel.detalhe)),
          ],
        ),
        const Spacer(),
        _Foto(c, largura: 132, altura: 132, redonda: true),
        const SizedBox(height: 14),
        _Texto(c, c.dados.nomeMembro, _Papel.nome, centralizado: true),
        _Texto(c, c.dados.validade, _Papel.detalhe, centralizado: true),
        const Spacer(),
        _AreaQr(c, lado: 160),
        const SizedBox(height: 6),
        _Numero(c),
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
        _Papel.nome => (150.0, 20.0, 1.0),
        _Papel.detalhe => (110.0, 12.0, 0.6),
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
      _Papel.nome => estilos.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
      _Papel.detalhe => estilos.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
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

class _Numero extends StatelessWidget {
  const _Numero(this.c, {this.centralizado = true});

  final PreviaCarteirinha c;
  final bool centralizado;

  @override
  Widget build(BuildContext context) {
    final numero = c.dados.numero;
    if (numero == null || c.esboco) return const SizedBox.shrink();
    return Text(
      'Nº $numero',
      textAlign: centralizado ? TextAlign.center : null,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.85),
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
      ),
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
          : Image.memory(
              c.logo!,
              fit: BoxFit.contain,
              semanticLabel: 'Logo da organização',
              errorBuilder: (_, _, _) => Icon(Icons.shield_outlined, color: c.cor, size: tamanho * 0.6),
            ),
    );
  }
}

/// Foto do membro com moldura branca; sem foto, uma silhueta. No app do
/// membro, um selo de câmera indica que dá para trocar.
class _Foto extends StatelessWidget {
  const _Foto(this.c, {required this.largura, required this.altura, required this.redonda});

  final PreviaCarteirinha c;
  final double largura;
  final double altura;
  final bool redonda;

  @override
  Widget build(BuildContext context) {
    final foto = c.esboco ? null : c.dados.foto;
    final silhueta = Icon(Icons.person, size: min(largura, altura) * 0.55, color: Colors.white.withValues(alpha: 0.85));
    final moldura = Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: redonda ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: redonda ? null : BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: foto != null
          ? Image.memory(
              foto,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              semanticLabel: 'Foto do membro',
              // Arquivo corrompido: mostra a silhueta em vez do erro.
              errorBuilder: (_, _, _) => silhueta,
            )
          : c.esboco
          ? null
          : silhueta,
    );

    final aoTocar = c.aoTocarFoto;
    if (aoTocar == null || c.esboco) return moldura;
    // Nó próprio: o leitor de tela anuncia o botão da foto separado do cartão.
    return Semantics(
      container: true,
      button: true,
      label: foto == null ? 'Adicionar foto' : 'Trocar foto',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: aoTocar,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            moldura,
            Positioned(
              right: redonda ? 2 : -6,
              bottom: redonda ? 2 : -6,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6)],
                ),
                child: Icon(Icons.photo_camera, size: 16, color: c._segunda),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quadro branco com o QR Code (ou o aviso que toma o lugar dele).
class _AreaQr extends StatelessWidget {
  const _AreaQr(this.c, {required this.lado});

  final PreviaCarteirinha c;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final aviso = c.dados.avisoQr;
    final codigo = c.dados.qrCodigo;
    final Widget conteudo;
    if (c.esboco || (codigo == null && aviso == null)) {
      conteudo = FittedBox(child: Icon(Icons.qr_code_2, color: c._segunda));
    } else if (aviso != null) {
      conteudo = Column(
        key: const Key('aviso-qr'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: lado * 0.22, color: c._segunda),
          const SizedBox(height: 10),
          Text(
            aviso,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c._segunda, fontWeight: FontWeight.w600),
          ),
        ],
      );
    } else {
      conteudo = QrImageView(
        key: const Key('qr-carteirinha'),
        data: codigo!,
        padding: EdgeInsets.zero,
        // Módulos escuros na cor da marca, sobre branco: leitura garantida.
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: c._segunda),
        dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: c._segunda),
        semanticsLabel: 'QR Code da carteirinha',
      );
    }
    final quadro = Container(
      width: lado,
      height: lado,
      padding: EdgeInsets.all(lado * 0.07),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(lado * 0.1)),
      child: conteudo,
    );
    final aoTocar = c.aoTocarQr;
    if (aoTocar == null || codigo == null || aviso != null || c.esboco) return Center(child: quadro);
    return Center(
      child: Semantics(
        container: true,
        button: true,
        label: 'Ampliar QR Code',
        child: GestureDetector(key: const Key('botao-ampliar-qr'), onTap: aoTocar, child: quadro),
      ),
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
