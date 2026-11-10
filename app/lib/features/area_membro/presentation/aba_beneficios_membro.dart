import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/contraste.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../beneficios/domain/beneficio.dart';
import '../../beneficios/presentation/logo_parceiro.dart';
import '../../identidade/domain/organizacao.dart';
import '../domain/carteirinha_membro.dart';

/// Aba de benefícios do membro (RF09): banner nas cores da organização e os
/// benefícios do plano como cupons. Tocar num cupom abre os detalhes.
class AbaBeneficiosMembro extends StatefulWidget {
  const AbaBeneficiosMembro({super.key, required this.organizacao, required this.aoMostrarCarteirinha});

  final Organizacao? organizacao;

  /// Leva o membro de volta à aba da carteirinha, para mostrar ao parceiro.
  final VoidCallback aoMostrarCarteirinha;

  @override
  State<AbaBeneficiosMembro> createState() => _AbaBeneficiosMembroState();
}

class _AbaBeneficiosMembroState extends State<AbaBeneficiosMembro> {
  List<Beneficio>? _beneficios;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final lista = await context.read<AreaMembroRepositorio>().beneficios();
      if (mounted) setState(() => _beneficios = lista);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  Color get _cor => Contraste.lerHex(widget.organizacao?.corPrincipal ?? '') ?? Cores.marca;

  Color get _corSecundaria =>
      Contraste.lerHex(widget.organizacao?.corSecundaria ?? '') ?? Color.lerp(_cor, Colors.black, 0.35)!;

  void _abrirDetalhes(Beneficio b) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _DetalhesBeneficio(
        beneficio: b,
        cor: _cor,
        corSecundaria: _corSecundaria,
        aoMostrarCarteirinha: () {
          Navigator.pop(context);
          widget.aoMostrarCarteirinha();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = _beneficios;
    if (_erro != null) return AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar);
    if (lista == null) return const Center(child: CircularProgressIndicator());

    final texto = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _Banner(
                quantidade: lista.length,
                cor: _cor,
                corSecundaria: _corSecundaria,
                aoMostrarCarteirinha: widget.aoMostrarCarteirinha,
              ),
              if (lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                  child: Column(
                    children: [
                      const Icon(Icons.redeem_outlined, size: 48, color: Cores.textoSecundario),
                      const SizedBox(height: 12),
                      Text(
                        'Seu plano ainda não tem benefícios disponíveis.',
                        textAlign: TextAlign.center,
                        style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
                      ),
                    ],
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 26, 4, 12),
                  child: Text(
                    'DISPONÍVEIS PARA VOCÊ',
                    style: texto.labelMedium?.copyWith(
                      color: Cores.textoSecundario,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final b in lista) ...[
                  _Cupom(beneficio: b, cor: _cor, corSecundaria: _corSecundaria, aoTocar: () => _abrirDetalhes(b)),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_outlined, size: 16, color: Cores.textoSecundario),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Novos benefícios aparecem aqui assim que forem liberados.',
                        textAlign: TextAlign.center,
                        style: texto.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho nas cores da organização, com o total de benefícios.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.quantidade,
    required this.cor,
    required this.corSecundaria,
    required this.aoMostrarCarteirinha,
  });

  final int quantidade;
  final Color cor;
  final Color corSecundaria;
  final VoidCallback aoMostrarCarteirinha;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final resumo = switch (quantidade) {
      0 => 'Fique de olho: logo tem novidade.',
      1 => '1 vantagem exclusiva no seu plano',
      _ => '$quantidade vantagens exclusivas no seu plano',
    };
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cor, corSecundaria]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          // Presente grande e apagado ao fundo, só de enfeite.
          Positioned(
            right: -18,
            bottom: -26,
            child: Icon(Icons.redeem, size: 150, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seus benefícios',
                  style: texto.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(resumo, style: texto.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 16),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    key: const Key('banner-ver-carteirinha'),
                    onTap: aoMostrarCarteirinha,
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2, size: 18, color: corSecundaria),
                          const SizedBox(width: 6),
                          Text(
                            'Mostrar carteirinha',
                            style: texto.labelLarge?.copyWith(color: corSecundaria, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Termina em 3 dias" quando o fim está perto; senão, a vigência por extenso.
(String, bool) _validade(Beneficio b) {
  final fim = b.vigFim;
  if (fim != null) {
    final dias = fim.difference(Datas.hoje()).inDays;
    if (dias == 0) return ('Último dia!', true);
    if (dias > 0 && dias <= 7) return ('Termina em $dias ${dias == 1 ? 'dia' : 'dias'}', true);
  }
  return (b.descricaoVigencia, false);
}

/// Benefício como cupom destacável: o desconto no canhoto colorido e, depois
/// do picote, parceiro, nome e validade.
class _Cupom extends StatelessWidget {
  const _Cupom({required this.beneficio, required this.cor, required this.corSecundaria, required this.aoTocar});

  final Beneficio beneficio;
  final Color cor;
  final Color corSecundaria;
  final VoidCallback aoTocar;

  static const _canhoto = 104.0;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final b = beneficio;
    final (validade, terminando) = _validade(b);
    final percentual = b.tipoDesconto == TipoDesconto.percentual;

    return Semantics(
      button: true,
      label: '${b.nome}, ${b.valorCurto} de desconto${b.parceiro == null ? '' : ' em ${b.parceiro}'}. $validade',
      excludeSemantics: true,
      child: ClipPath(
        clipper: const _FormaCupom(canhoto: _canhoto),
        child: Material(
          color: Cores.superficie,
          child: InkWell(
            onTap: aoTocar,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Canhoto com o desconto.
                  Container(
                    width: _canhoto,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cor, corSecundaria],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          child: Text(
                            b.valorCurto,
                            style: texto.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          percentual ? 'OFF' : 'de desconto',
                          textAlign: TextAlign.center,
                          style: texto.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w800,
                            letterSpacing: percentual ? 2 : 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _Picote(),
                  // Corpo do cupom.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              LogoParceiro(logo: b.logo, iniciais: b.iniciais, tamanho: 28),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  b.parceiro ?? 'Parceiro do clube',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: texto.labelMedium?.copyWith(color: Cores.textoSecundario),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            b.nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
                          ),
                          if (b.descricao != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              b.descricao!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: texto.bodySmall?.copyWith(height: 1.35),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                terminando ? Icons.timer_outlined : Icons.event_available_outlined,
                                size: 15,
                                color: terminando ? Cores.alerta : Cores.sucesso,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  validade,
                                  style: texto.labelSmall?.copyWith(
                                    color: terminando ? Cores.alerta : Cores.sucesso,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.chevron_right, color: Cores.textoSecundario),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha tracejada entre o canhoto e o corpo do cupom.
class _Picote extends StatelessWidget {
  const _Picote();

  @override
  Widget build(BuildContext context) => SizedBox(width: 2, child: CustomPaint(painter: _PintorPicote()));
}

class _PintorPicote extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()
      ..color = Cores.fundo
      ..strokeWidth = 2;
    const traco = 6.0;
    const espaco = 5.0;
    // Começa e termina longe dos furos do picote.
    for (var y = 14.0; y < size.height - 14; y += traco + espaco) {
      canvas.drawLine(Offset(1, y), Offset(1, (y + traco).clamp(0, size.height - 14)), tinta);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Retângulo arredondado com dois furos meia-lua na linha do picote.
class _FormaCupom extends CustomClipper<Path> {
  const _FormaCupom({required this.canhoto});

  final double canhoto;

  @override
  Path getClip(Size size) {
    const raio = 18.0;
    const furo = 9.0;
    final x = canhoto + 1;
    final cartao = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(raio)));
    final furos = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: furo))
      ..addOval(Rect.fromCircle(center: Offset(x, size.height), radius: furo));
    return Path.combine(PathOperation.difference, cartao, furos);
  }

  @override
  bool shouldReclip(covariant _FormaCupom oldClipper) => oldClipper.canhoto != canhoto;
}

/// Detalhes do benefício e como usar, em uma folha que sobe de baixo.
class _DetalhesBeneficio extends StatelessWidget {
  const _DetalhesBeneficio({
    required this.beneficio,
    required this.cor,
    required this.corSecundaria,
    required this.aoMostrarCarteirinha,
  });

  final Beneficio beneficio;
  final Color cor;
  final Color corSecundaria;
  final VoidCallback aoMostrarCarteirinha;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final b = beneficio;
    final (validade, terminando) = _validade(b);

    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('detalhes-beneficio'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoParceiro(logo: b.logo, iniciais: b.iniciais, tamanho: 76),
            const SizedBox(height: 12),
            if (b.parceiro != null) Text(b.parceiro!, style: texto.labelLarge?.copyWith(color: Cores.textoSecundario)),
            const SizedBox(height: 4),
            Text(
              b.nome,
              textAlign: TextAlign.center,
              style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cor, corSecundaria]),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${b.valorCurto} de desconto',
                style: texto.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              validade,
              style: texto.labelMedium?.copyWith(
                color: terminando ? Cores.alerta : Cores.textoSecundario,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (b.descricao != null) ...[
              const SizedBox(height: 18),
              Text(b.descricao!, textAlign: TextAlign.center, style: texto.bodyMedium?.copyWith(height: 1.45)),
            ],
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Cores.superficieElevada, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Como usar', style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _Passo(numero: 1, texto: 'Vá até ${b.parceiro ?? 'o parceiro'}.'),
                  const _Passo(numero: 2, texto: 'Antes de pagar, mostre sua carteirinha com o QR Code.'),
                  const _Passo(numero: 3, texto: 'O desconto é aplicado na hora.', ultimo: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('detalhes-mostrar-carteirinha'),
                onPressed: aoMostrarCarteirinha,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Mostrar minha carteirinha'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({required this.numero, required this.texto, this.ultimo = false});

  final int numero;
  final String texto;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Cores.primaria.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Text(
              '$numero',
              style: const TextStyle(color: Cores.primaria, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
