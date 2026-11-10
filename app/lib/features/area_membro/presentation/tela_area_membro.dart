import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/contraste.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../auth/presentation/sair.dart';
import '../../identidade/domain/organizacao.dart';
import '../../identidade/presentation/previa_carteirinha.dart';
import '../domain/carteirinha_membro.dart';
import 'aba_beneficios_membro.dart';
import 'aba_locais_membro.dart';
import 'tela_primeiro_acesso.dart';

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

  /// Dados do membro; enquanto o primeiro acesso não é concluído, a área
  /// mostra o formulário de cadastro no lugar da carteirinha.
  CadastroMembro? _cadastro;
  String? _erroCadastro;

  /// O membro tocou em "Preencher depois": o formulário volta no próximo login.
  bool _adiouCadastro = false;

  @override
  void initState() {
    super.initState();
    _carregarOrganizacao();
    _carregarCadastro();
  }

  Future<void> _carregarCadastro() async {
    setState(() => _erroCadastro = null);
    try {
      final cadastro = await context.read<AreaMembroRepositorio>().cadastro();
      if (mounted) setState(() => _cadastro = cadastro);
    } catch (e) {
      if (mounted) setState(() => _erroCadastro = mensagemDeErro(e));
    }
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
    final cadastro = _cadastro;
    if (cadastro == null) {
      return Scaffold(
        appBar: AppBar(
          actions: [IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: _sair)],
        ),
        body: _erroCadastro != null
            ? AvisoTela(icone: Icons.cloud_off, texto: _erroCadastro!, aoTentarDeNovo: _carregarCadastro)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    if (cadastro.pendente && !_adiouCadastro) {
      return TelaPrimeiroAcesso(
        cadastro: cadastro,
        aoSair: _sair,
        aoConcluir: (c) => setState(() => _cadastro = c),
        aoAdiar: TelaPrimeiroAcesso.obrigatorio ? null : () => setState(() => _adiouCadastro = true),
      );
    }

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
          AbaBeneficiosMembro(organizacao: org, aoMostrarCarteirinha: () => setState(() => _aba = 0)),
          AbaLocaisMembro(organizacao: org, aoMostrarCarteirinha: () => setState(() => _aba = 0)),
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

/// QR Code ampliado: ocupa a largura da tela, com nome e número para o
/// operador conferir. Toque em qualquer lugar para fechar.
class _QrAmpliado extends StatelessWidget {
  const _QrAmpliado({required this.codigo, required this.nome, required this.numero});

  final String codigo;
  final String nome;
  final String numero;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return SafeArea(
      child: GestureDetector(
        key: const Key('qr-ampliado'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        textAlign: TextAlign.center,
                        style: texto.titleLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text('Nº $numero', style: texto.titleSmall?.copyWith(color: Colors.black54, letterSpacing: 2)),
                      const SizedBox(height: 20),
                      // Preto no branco: o contraste máximo facilita a leitura pela câmera.
                      // Em telas baixas (celular deitado), o QR diminui para caber.
                      Flexible(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: QrImageView(
                            data: codigo,
                            padding: EdgeInsets.zero,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                            semanticsLabel: 'QR Code da carteirinha ampliado',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.touch_app_outlined, size: 18, color: Colors.black45),
                          const SizedBox(width: 6),
                          Text('Toque para fechar', style: texto.bodySmall?.copyWith(color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

  /// QR Code em tela cheia, preto no branco, para o leitor do operador.
  void _ampliarQr(CarteirinhaMembro c) {
    final codigo = c.qrCodigo;
    if (codigo == null) return;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animacao, _, filho) => FadeTransition(
        opacity: animacao,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: animacao, curve: Curves.easeOutBack)),
          child: filho,
        ),
      ),
      pageBuilder: (context, _, _) => _QrAmpliado(codigo: codigo, nome: c.nomeMembro, numero: c.numero),
    );
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
        aoTocarQr: () => _ampliarQr(c),
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
