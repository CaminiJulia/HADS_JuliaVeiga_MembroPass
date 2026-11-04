import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/contraste.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../auth/presentation/sair.dart';
import '../../beneficios/domain/beneficio.dart';
import '../../beneficios/presentation/cartao_beneficio.dart';
import '../../identidade/domain/organizacao.dart';
import '../../identidade/presentation/previa_carteirinha.dart';
import '../../unidades/domain/unidade_evento.dart';
import '../domain/carteirinha_membro.dart';

/// Área do membro (RF05 e RF09): carteirinha com QR Code, benefícios do plano
/// e os locais onde a carteirinha é aceita.
class TelaAreaMembro extends StatefulWidget {
  const TelaAreaMembro({super.key});

  @override
  State<TelaAreaMembro> createState() => _TelaAreaMembroState();
}

class _TelaAreaMembroState extends State<TelaAreaMembro> {
  int _aba = 0;
  Organizacao? _organizacao;

  @override
  void initState() {
    super.initState();
    _carregarOrganizacao();
  }

  Future<void> _carregarOrganizacao() async {
    try {
      final org = await context.read<OrganizacaoRepositorio>().buscar();
      if (mounted) setState(() => _organizacao = org);
    } catch (_) {
      // Sem a marca, a carteirinha usa as cores padrão e a aba avisa do erro.
    }
  }

  Future<void> _sair() async {
    final confirmou = await confirmar(
      context,
      titulo: 'Sair da conta?',
      mensagem: 'Você vai precisar entrar de novo para mostrar a carteirinha.',
      acao: 'Sair',
    );
    if (confirmou && mounted) sairDaConta(context);
  }

  @override
  Widget build(BuildContext context) {
    final org = _organizacao;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            if (org?.logo != null) ...[
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                child: Image.memory(org!.logo!, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(org?.nome ?? 'Minha carteirinha', overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: _sair)],
      ),
      body: IndexedStack(
        index: _aba,
        children: [
          _AbaCarteirinha(organizacao: org),
          const _AbaBeneficios(),
          const _AbaLocais(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Carteirinha',
          ),
          NavigationDestination(
            icon: Icon(Icons.redeem_outlined),
            selectedIcon: Icon(Icons.redeem),
            label: 'Benefícios',
          ),
          NavigationDestination(icon: Icon(Icons.place_outlined), selectedIcon: Icon(Icons.place), label: 'Locais'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carteirinha

class _AbaCarteirinha extends StatefulWidget {
  const _AbaCarteirinha({required this.organizacao});

  final Organizacao? organizacao;

  @override
  State<_AbaCarteirinha> createState() => _AbaCarteirinhaState();
}

class _AbaCarteirinhaState extends State<_AbaCarteirinha> {
  CarteirinhaMembro? _carteirinha;
  String? _erro;
  bool _renovando = false;

  /// Atualiza a contagem do QR a cada segundo e pede um novo antes de expirar.
  Timer? _relogio;

  /// Segundos até o QR atual expirar, contados pelo próprio timer.
  int _restante = 0;

  /// Depois de uma falha, espera este tanto (em segundos) antes de tentar de novo.
  int _esperaNovaTentativa = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _aCadaSegundo());
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _erro = null;
      _renovando = true;
    });
    try {
      final c = await context.read<AreaMembroRepositorio>().carteirinha();
      if (mounted) {
        setState(() {
          _carteirinha = c;
          _restante = c.qrExpiraEm?.difference(DateTime.now()).inSeconds ?? 0;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final mensagem = mensagemDeErro(e);
      setState(() {
        _erro = mensagem;
        _esperaNovaTentativa = 20;
      });
      // Com a carteirinha já na tela, avisa sem tirar o que está sendo mostrado.
      if (_carteirinha != null) avisar(context, 'Não foi possível atualizar a carteirinha. $mensagem');
    } finally {
      if (mounted) setState(() => _renovando = false);
    }
  }

  void _aCadaSegundo() {
    if (_carteirinha?.qrCodigo == null || !mounted) return;
    setState(() {
      _restante--;
      if (_esperaNovaTentativa > 0) _esperaNovaTentativa--;
    });
    // Renova com folga, para o operador nunca ler um código no limite.
    if (!_renovando && _esperaNovaTentativa == 0 && _restante <= 15) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final c = _carteirinha;
    if (c == null) {
      return _erro != null
          ? AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar)
          : const Center(child: CircularProgressIndicator());
    }

    final org = widget.organizacao;
    final cor = Contraste.lerHex(org?.corPrincipal ?? '') ?? Cores.marca;
    final hoje = Datas.hoje();
    final situacao = c.situacao(hoje);

    return RefreshIndicator(
      onRefresh: _carregar,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Opacity(
                opacity: situacao.semQr ? 0.55 : 1,
                child: PreviaCarteirinha(
                  cor: cor,
                  corSecundaria: Contraste.lerHex(org?.corSecundaria ?? ''),
                  estilo: org?.estiloFundo ?? EstiloFundo.degrade,
                  modelo: org?.modelo ?? ModeloCarteirinha.classico,
                  nomeOrganizacao: org?.nome ?? '',
                  logo: org?.logo,
                  dados: DadosCarteirinha(
                    nomeMembro: c.nomeMembro,
                    plano: 'Plano ${c.planoNome}',
                    validade: 'Válida até ${Datas.formatar(c.dataVencimento)}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AvisoSituacao(carteirinha: c, situacao: situacao, hoje: hoje),
              const SizedBox(height: 16),
              if (situacao.semQr)
                _SemQr(situacao)
              else
                _PainelQr(
                  carteirinha: c,
                  restante: _restante,
                  corModulos: Color.lerp(cor, Colors.black, 0.35)!,
                  aoRenovar: _carregar,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa com a situação: em dia, vencendo, vencida ou bloqueada.
class _AvisoSituacao extends StatelessWidget {
  const _AvisoSituacao({required this.carteirinha, required this.situacao, required this.hoje});

  final CarteirinhaMembro carteirinha;
  final SituacaoCarteirinha situacao;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    final dias = carteirinha.diasParaVencer(hoje);
    final vencimento = Datas.formatar(carteirinha.dataVencimento);
    final (icone, cor, fundo, titulo, texto) = switch (situacao) {
      SituacaoCarteirinha.emDia => (
        Icons.verified_outlined,
        Cores.sucesso,
        Cores.sucessoFundo,
        'Carteirinha em dia',
        'Válida até $vencimento.',
      ),
      SituacaoCarteirinha.venceEmBreve => (
        Icons.schedule,
        Cores.alerta,
        Cores.alertaFundo,
        dias == 0 ? 'Vence hoje' : 'Vence em $dias ${dias == 1 ? 'dia' : 'dias'}',
        'Combine a renovação com a administração para continuar com acesso.',
      ),
      SituacaoCarteirinha.vencida => (
        Icons.error_outline,
        Cores.alerta,
        Cores.alertaFundo,
        'Pagamento vencido em $vencimento',
        'A carteirinha ainda funciona, mas pode ser bloqueada. Regularize com a administração.',
      ),
      SituacaoCarteirinha.bloqueada => (
        Icons.lock_outline,
        Cores.erro,
        Cores.erroFundo,
        'Carteirinha bloqueada',
        'Procure a administração da sua organização para regularizar.',
      ),
      SituacaoCarteirinha.invalidada => (
        Icons.block,
        Cores.erro,
        Cores.erroFundo,
        'Carteirinha inativa',
        'Procure a administração da sua organização.',
      ),
    };

    return Container(
      key: const Key('aviso-situacao-carteirinha'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(color: cor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(texto, style: TextStyle(color: cor.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// QR Code grande, sobre branco, com o número e a contagem até renovar.
class _PainelQr extends StatelessWidget {
  const _PainelQr({
    required this.carteirinha,
    required this.restante,
    required this.corModulos,
    required this.aoRenovar,
  });

  final CarteirinhaMembro carteirinha;
  final int restante;
  final Color corModulos;
  final VoidCallback aoRenovar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final segundos = restante.clamp(0, 9999);
    final contagem = '${segundos ~/ 60}:${(segundos % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(
            'Apresente este código na entrada',
            style: texto.titleSmall?.copyWith(color: Cores.noPrimaria, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          // Código expirado não serve no check-in: sai da tela até renovar.
          if (segundos == 0)
            SizedBox(
              key: const Key('qr-expirado'),
              width: 240,
              height: 240,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF5A5E85)),
                  const SizedBox(height: 10),
                  Text(
                    'Código expirado. Verifique sua conexão e gere um novo.',
                    textAlign: TextAlign.center,
                    style: texto.bodyMedium?.copyWith(color: const Color(0xFF5A5E85)),
                  ),
                ],
              ),
            )
          else
            QrImageView(
              key: const Key('qr-carteirinha'),
              data: carteirinha.qrCodigo!,
              size: 240,
              padding: EdgeInsets.zero,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: corModulos),
              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: corModulos),
              semanticsLabel: 'QR Code da carteirinha',
            ),
          const SizedBox(height: 12),
          Text(
            'Nº ${carteirinha.numero}',
            style: texto.titleMedium?.copyWith(
              color: Cores.noPrimaria,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.autorenew, size: 16, color: Color(0xFF5A5E85)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Novo código em $contagem',
                  key: const Key('contagem-qr'),
                  textAlign: TextAlign.center,
                  style: texto.bodySmall?.copyWith(color: const Color(0xFF5A5E85)),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: aoRenovar,
            style: TextButton.styleFrom(foregroundColor: Cores.marca),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Gerar novo código'),
          ),
        ],
      ),
    );
  }
}

class _SemQr extends StatelessWidget {
  const _SemQr(this.situacao);

  final SituacaoCarteirinha situacao;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return CartaoItem(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            const Icon(Icons.qr_code_2, size: 56, color: Cores.textoSecundario),
            const SizedBox(height: 10),
            Text('QR Code indisponível', style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Com a carteirinha ${situacao.rotulo.toLowerCase()}, não é possível fazer check‑in.',
              textAlign: TextAlign.center,
              style: texto.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Benefícios e locais

/// Carrega uma lista da área do membro com estados de carregando, erro e vazio.
class _AbaLista<T> extends StatefulWidget {
  const _AbaLista({
    required this.buscar,
    required this.vazio,
    required this.iconeVazio,
    required this.cabecalho,
    required this.item,
  });

  final Future<List<T>> Function(AreaMembroRepositorio repositorio) buscar;
  final String vazio;
  final IconData iconeVazio;
  final String cabecalho;
  final Widget Function(T item) item;

  @override
  State<_AbaLista<T>> createState() => _AbaListaState<T>();
}

class _AbaListaState<T> extends State<_AbaLista<T>> {
  List<T>? _itens;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final itens = await widget.buscar(context.read<AreaMembroRepositorio>());
      if (mounted) setState(() => _itens = itens);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final itens = _itens;
    if (_erro != null) return AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar);
    if (itens == null) return const Center(child: CircularProgressIndicator());
    if (itens.isEmpty) return AvisoTela(icone: widget.iconeVazio, texto: widget.vazio);

    return RefreshIndicator(
      onRefresh: _carregar,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: itens.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => i == 0
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: Text(widget.cabecalho, style: Theme.of(context).textTheme.bodyMedium),
                  )
                : widget.item(itens[i - 1]),
          ),
        ),
      ),
    );
  }
}

class _AbaBeneficios extends StatelessWidget {
  const _AbaBeneficios();

  @override
  Widget build(BuildContext context) {
    return _AbaLista<Beneficio>(
      buscar: (r) => r.beneficios(),
      vazio: 'Seu plano ainda não tem benefícios disponíveis.',
      iconeVazio: Icons.redeem_outlined,
      cabecalho: 'Mostre sua carteirinha ao parceiro para usar o desconto.',
      item: (b) =>
          CartaoBeneficio(beneficio: b, situacao: SituacaoVigencia.vigente, planos: const [], mostrarPlanos: false),
    );
  }
}

class _AbaLocais extends StatelessWidget {
  const _AbaLocais();

  @override
  Widget build(BuildContext context) {
    return _AbaLista<UnidadeEvento>(
      buscar: (r) => r.locais(),
      vazio: 'Ainda não há locais cadastrados para o seu plano.',
      iconeVazio: Icons.place_outlined,
      cabecalho: 'Onde sua carteirinha é aceita.',
      item: (l) => _CartaoLocalMembro(l),
    );
  }
}

class _CartaoLocalMembro extends StatelessWidget {
  const _CartaoLocalMembro(this.local);

  final UnidadeEvento local;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final imagem = local.imagem;
    final localizacao = local.localizacao;
    final periodo = local.evento && local.dataInicio != null && local.dataFim != null
        ? Datas.periodoPorExtenso(local.dataInicio!, local.dataFim!)
        : null;

    return CartaoItem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imagem != null)
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.memory(imagem, fit: BoxFit.cover, semanticLabel: 'Imagem de ${local.nome}'),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Cores.primaria.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    local.evento ? Icons.celebration_outlined : Icons.storefront_outlined,
                    color: Cores.primaria,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(local.nome, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(local.evento ? 'Evento' : 'Unidade', style: texto.labelMedium),
                      if (periodo != null) ...[
                        const SizedBox(height: 8),
                        _Linha(icone: Icons.event_outlined, texto: periodo),
                      ],
                      if (localizacao != null) ...[
                        const SizedBox(height: 6),
                        _Linha(icone: Icons.place_outlined, texto: localizacao),
                      ],
                    ],
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

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 16, color: Cores.textoSecundario),
        const SizedBox(width: 6),
        Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}
