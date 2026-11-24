import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/tema/cores.dart';
import '../domain/checkin.dart';

/// Identifica a carteirinha pelo QR Code (ou, se ele não ler, pelo número
/// digitado). Devolve `null` se o operador desistir.
/// Os testes trocam a câmera por [LeitorQrSimulado].
abstract interface class LeitorQr {
  Future<IdentificacaoCarteirinha?> ler(BuildContext context);
}

/// Abre a câmera traseira em tela cheia.
class LeitorQrCamera implements LeitorQr {
  const LeitorQrCamera();

  @override
  Future<IdentificacaoCarteirinha?> ler(BuildContext context) =>
      Navigator.of(context).push<IdentificacaoCarteirinha>(MaterialPageRoute(builder: (_) => const TelaLeitorQr()));
}

/// Devolve sempre [codigo] como QR Code lido, sem câmera.
class LeitorQrSimulado implements LeitorQr {
  LeitorQrSimulado([this.codigo]);

  /// O próximo "QR Code lido"; `null` simula o operador voltando sem ler.
  String? codigo;

  @override
  Future<IdentificacaoCarteirinha?> ler(BuildContext context) async => codigo == null ? null : PorQr(codigo!);
}

/// Pede o número impresso na carteirinha ("Nº 38F29DBA"), para quando o QR
/// Code não lê. Devolve o número em maiúsculas, ou `null` se cancelar.
Future<String?> pedirNumeroCarteirinha(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _DialogoNumero());

class _DialogoNumero extends StatefulWidget {
  const _DialogoNumero();

  @override
  State<_DialogoNumero> createState() => _DialogoNumeroState();
}

class _DialogoNumeroState extends State<_DialogoNumero> {
  final _campo = TextEditingController();

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  bool get _completo => PorNumero.formato.hasMatch(_campo.text);

  void _confirmar() {
    if (_completo) Navigator.of(context).pop(_campo.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Número da carteirinha'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digite o número que aparece abaixo do QR Code, na carteirinha do membro.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Cores.textoSecundario),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('campo-numero-carteirinha'),
            controller: _campo,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 8,
            style: const TextStyle(fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(prefixText: 'Nº ', hintText: '38F29DBA', counterText: ''),
            // Só 0-9 e A-F, já em maiúsculas: é o que está impresso.
            inputFormatters: [
              TextInputFormatter.withFunction((_, novo) => novo.copyWith(text: novo.text.toUpperCase())),
              FilteringTextInputFormatter.allow(RegExp('[0-9A-F]')),
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('botao-validar-numero'),
          onPressed: _completo ? _confirmar : null,
          child: const Text('Validar'),
        ),
      ],
    );
  }
}

/// Câmera com a moldura de mira. Fecha sozinha no primeiro QR Code lido.
class TelaLeitorQr extends StatefulWidget {
  const TelaLeitorQr({super.key});

  @override
  State<TelaLeitorQr> createState() => _TelaLeitorQrState();
}

class _TelaLeitorQrState extends State<TelaLeitorQr> {
  final _camera = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  /// A câmera continua mandando o mesmo código enquanto ele está na mira.
  bool _lido = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _aoDetectar(BarcodeCapture captura) {
    if (_lido) return;
    final codigo = captura.barcodes.map((b) => b.rawValue).nonNulls.firstOrNull;
    if (codigo == null || codigo.isEmpty) return;
    _lido = true;
    Navigator.of(context).pop(PorQr(codigo));
  }

  /// O QR Code não lê (tela trincada, brilho baixo...): digita o número.
  Future<void> _digitarNumero() async {
    // Para a câmera enquanto digita, para não ler um QR por trás do diálogo.
    // Se ela nem abriu (sem permissão), parar e reabrir falha: tudo bem.
    try {
      await _camera.stop();
    } catch (_) {}
    if (!mounted) return;
    final numero = await pedirNumeroCarteirinha(context);
    if (!mounted) return;
    if (numero != null) {
      _lido = true;
      Navigator.of(context).pop(PorNumero(numero));
    } else {
      try {
        await _camera.start();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Ler carteirinha'),
        actions: [
          ValueListenableBuilder(
            valueListenable: _camera,
            builder: (context, estado, _) => estado.torchState == TorchState.unavailable
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: estado.torchState == TorchState.on ? 'Desligar lanterna' : 'Ligar lanterna',
                    icon: Icon(estado.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off),
                    onPressed: _camera.toggleTorch,
                  ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _camera, onDetect: _aoDetectar, errorBuilder: _erroCamera),
          // Mira no centro, do tamanho que o QR da carteirinha costuma ocupar.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Aponte para o QR Code na carteirinha do membro',
                    textAlign: TextAlign.center,
                    style: texto.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const Key('botao-camera-digitar-numero'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      backgroundColor: Colors.black45,
                    ),
                    onPressed: _digitarNumero,
                    icon: const Icon(Icons.keyboard_outlined),
                    label: const Text('Não está lendo? Digitar o número'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _erroCamera(BuildContext context, MobileScannerException erro) {
    final semPermissao = erro.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Cores.fundo,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                semPermissao ? Icons.no_photography_outlined : Icons.videocam_off_outlined,
                size: 56,
                color: Cores.lilas,
              ),
              const SizedBox(height: 16),
              Text(
                semPermissao
                    ? 'Permita o uso da câmera nas configurações do celular para ler as carteirinhas.'
                    : 'Não foi possível abrir a câmera.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Cores.textoSecundario),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _digitarNumero,
                icon: const Icon(Icons.keyboard_outlined),
                label: const Text('Digitar o número da carteirinha'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Voltar')),
            ],
          ),
        ),
      ),
    );
  }
}
