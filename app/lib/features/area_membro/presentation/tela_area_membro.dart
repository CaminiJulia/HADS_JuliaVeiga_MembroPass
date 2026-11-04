import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
  bool _salvandoFoto = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Busca a carteirinha. O QR Code é fixo: só muda quando a administração
  /// bloqueia, desativa ou libera um novo ciclo.
  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final c = await context.read<AreaMembroRepositorio>().carteirinha();
      if (mounted) setState(() => _carteirinha = c);
    } catch (e) {
      if (!mounted) return;
      final mensagem = mensagemDeErro(e);
      setState(() => _erro = mensagem);
      // Com a carteirinha já na tela, avisa sem tirar o que está sendo mostrado.
      if (_carteirinha != null) avisar(context, 'Não foi possível atualizar a carteirinha. $mensagem');
    }
  }

  Future<void> _opcoesFoto() async {
    final temFoto = _carteirinha?.foto != null;
    final escolha = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(context, 'galeria'),
            ),
            if (temFoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Cores.erro),
                title: const Text('Remover foto', style: TextStyle(color: Cores.erro)),
                onTap: () => Navigator.pop(context, 'remover'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (escolha == null || !mounted) return;
    if (escolha == 'remover') return _salvarFoto(null, null);

    final arquivo = await ImagePicker().pickImage(
      source: escolha == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 512 * 1024) {
      avisar(context, 'A foto pode ter no máximo 512 KB.');
      return;
    }
    await _salvarFoto(bytes, arquivo.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
  }

  Future<void> _salvarFoto(Uint8List? foto, String? tipo) async {
    setState(() => _salvandoFoto = true);
    try {
      final c = await context.read<AreaMembroRepositorio>().salvarFoto(foto, tipo: tipo);
      if (!mounted) return;
      setState(() => _carteirinha = c);
      avisar(context, foto == null ? 'Foto removida.' : 'Foto atualizada na carteirinha.');
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _salvandoFoto = false);
    }
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
    final avisoQr = switch (situacao) {
      SituacaoCarteirinha.bloqueada => 'Carteirinha bloqueada.\nCheck‑in indisponível.',
      SituacaoCarteirinha.invalidada => 'Carteirinha inativa.\nCheck‑in indisponível.',
      _ => null,
    };
    // Em dia, a própria carteirinha já diz a validade; o aviso só aparece
    // quando há algo a fazer.
    final mostrarAviso = situacao != SituacaoCarteirinha.emDia;

    final cartao = Opacity(
      opacity: situacao.semQr ? 0.6 : 1,
      child: PreviaCarteirinha(
        cor: cor,
        corSecundaria: Contraste.lerHex(org?.corSecundaria ?? ''),
        estilo: org?.estiloFundo ?? EstiloFundo.degrade,
        modelo: org?.modelo ?? ModeloCarteirinha.classico,
        nomeOrganizacao: org?.nome ?? '',
        logo: org?.logo,
        aoTocarFoto: _salvandoFoto ? null : _opcoesFoto,
        dados: DadosCarteirinha(
          nomeMembro: c.nomeMembro,
          plano: 'Plano ${c.planoNome}',
          validade: 'Válida até ${Datas.formatar(c.dataVencimento)}',
          numero: c.numero,
          foto: c.foto,
          qrCodigo: avisoQr == null ? c.qrCodigo : null,
          avisoQr: avisoQr,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, restricoes) {
        // A carteirinha ocupa quase a tela toda: o maior tamanho que cabe na
        // altura, descontando o aviso e a linha de baixo.
        final reserva = 32 + (mostrarAviso ? 104 : 0) + (c.foto == null ? 30 : 0);
        final pelaAltura = (restricoes.maxHeight - reserva) * PreviaCarteirinha.proporcao;
        final largura = min(min(restricoes.maxWidth - 32, 440.0), max(pelaAltura, 240.0));

        return RefreshIndicator(
          onRefresh: _carregar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              if (mostrarAviso) ...[
                _AvisoSituacao(carteirinha: c, situacao: situacao, hoje: hoje),
                const SizedBox(height: 12),
              ],
              Center(
                child: SizedBox(width: largura, child: cartao),
              ),
              if (c.foto == null && !situacao.semQr)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Toque na foto para adicionar a sua.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
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
