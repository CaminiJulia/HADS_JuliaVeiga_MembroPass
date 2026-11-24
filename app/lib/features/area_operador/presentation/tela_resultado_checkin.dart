import 'package:flutter/material.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../perfil/presentation/avatar_perfil.dart';
import '../../planos/presentation/cor_plano.dart';
import '../domain/checkin.dart';

/// Cor, ícone e título de cada desfecho, iguais na tela de resultado e no histórico.
extension VisualDesfecho on DesfechoCheckin {
  Color get cor => switch (this) {
    DesfechoCheckin.liberado => Cores.sucesso,
    DesfechoCheckin.liberadoComAlerta => Cores.alerta,
    DesfechoCheckin.recusado => Cores.erro,
  };

  Color get fundo => switch (this) {
    DesfechoCheckin.liberado => Cores.sucessoFundo,
    DesfechoCheckin.liberadoComAlerta => Cores.alertaFundo,
    DesfechoCheckin.recusado => Cores.erroFundo,
  };

  IconData get icone => switch (this) {
    DesfechoCheckin.liberado => Icons.check_circle,
    DesfechoCheckin.liberadoComAlerta => Icons.error,
    DesfechoCheckin.recusado => Icons.cancel,
  };

  String get titulo => switch (this) {
    DesfechoCheckin.recusado => 'Entrada recusada',
    _ => 'Entrada liberada',
  };
}

/// Resultado da leitura em tela cheia, para o operador ver de relance.
/// Devolve `true` se ele tocar em "Ler próxima".
class TelaResultadoCheckin extends StatelessWidget {
  const TelaResultadoCheckin({super.key, required this.resultado, required this.localNome});

  final ResultadoCheckin resultado;
  final String localNome;

  @override
  Widget build(BuildContext context) {
    final desfecho = resultado.desfecho;
    final membro = resultado.membro;
    final texto = Theme.of(context).textTheme;
    final anterior = resultado.entradaAnteriorHoje;

    return Scaffold(
      backgroundColor: desfecho.fundo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(localNome),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Icon(desfecho.icone, key: Key('resultado-${desfecho.name}'), size: 88, color: desfecho.cor),
                  const SizedBox(height: 12),
                  Text(
                    desfecho.titulo,
                    textAlign: TextAlign.center,
                    style: texto.headlineSmall?.copyWith(color: desfecho.cor, fontWeight: FontWeight.w800),
                  ),
                  if (resultado.mensagem != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      resultado.mensagem!,
                      textAlign: TextAlign.center,
                      style: texto.bodyLarge?.copyWith(color: Cores.tinta, height: 1.35),
                    ),
                  ],
                  if (membro != null) ...[const SizedBox(height: 28), _CartaoMembro(membro)],
                  // O número não tem assinatura como o QR: a foto é a garantia.
                  if (resultado.forma == FormaCheckin.numero && membro != null)
                    const _Alerta(
                      icone: Icons.keyboard_outlined,
                      texto: 'Validada pelo número digitado. Confira se a foto é mesmo da pessoa.',
                    ),
                  if (resultado.vencida && membro != null)
                    _Alerta(
                      icone: Icons.event_busy,
                      texto:
                          'Pagamento vencido desde ${Datas.formatar(membro.dataVencimento)}. '
                          'Lembre o membro de procurar a administração.',
                    ),
                  if (anterior != null)
                    _Alerta(
                      icone: Icons.history,
                      texto: 'Esta carteirinha já entrou hoje neste local, às ${Datas.hora(anterior)}.',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: FilledButton.icon(
                key: const Key('botao-ler-proxima'),
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Ler próxima'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto grande para o operador conferir o rosto, com nome, plano e número.
class _CartaoMembro extends StatelessWidget {
  const _CartaoMembro(this.membro);

  final MembroLido membro;

  String get _iniciais {
    final partes = membro.nome.trim().split(RegExp(r'\s+'));
    return (partes.first[0] + (partes.length > 1 ? partes.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Cores.fundo.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          AvatarPerfil(iniciais: _iniciais, foto: membro.foto, tamanho: 132, borda: true),
          const SizedBox(height: 16),
          Text(
            membro.nome,
            textAlign: TextAlign.center,
            style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          // Wrap: um nome de plano comprido quebra a linha em vez de estourar.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PontoCorPlano(membro.planoCor, tamanho: 10),
              const SizedBox(width: 6),
              Text('Plano ${membro.planoNome}', style: texto.bodyMedium),
              Text('  ·  Nº ${membro.numero}', style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Alerta extends StatelessWidget {
  const _Alerta({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.alertaFundo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.alerta.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Cores.alerta, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Cores.tinta, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
