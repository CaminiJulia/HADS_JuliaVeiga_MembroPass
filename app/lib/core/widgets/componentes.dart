import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../formatacao/datas.dart';
import '../tema/cores.dart';

/// Mensagem centralizada para lista vazia ou erro de carregamento.
class AvisoTela extends StatelessWidget {
  const AvisoTela({super.key, required this.icone, required this.texto, this.aoTentarDeNovo});

  final IconData icone;
  final String texto;
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: Cores.lilas),
            const SizedBox(height: 16),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Cores.textoSecundario),
            ),
            if (aoTentarDeNovo != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: aoTentarDeNovo, child: const Text('Tentar de novo')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Etiqueta pequena de status ("Inativo", "Vencida"...).
class Selo extends StatelessWidget {
  const Selo(this.texto, {super.key, this.cor = Cores.borda, this.corTexto = Cores.tinta});

  final String texto;
  final Color cor;
  final Color corTexto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(20)),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: corTexto, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Cartão clicável das listas de cadastro.
class CartaoItem extends StatelessWidget {
  const CartaoItem({super.key, required this.child, this.aoTocar, this.esmaecido = false});

  final Widget child;
  final VoidCallback? aoTocar;

  /// Itens inativos aparecem mais apagados.
  final bool esmaecido;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Cores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Opacity(opacity: esmaecido ? 0.6 : 1, child: child),
      ),
    );
  }
}

/// Indicador de carregamento do tamanho do texto de um botão.
class CarregandoBotao extends StatelessWidget {
  const CarregandoBotao({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 22,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Cores.noPrimaria),
    );
  }
}

/// Mensagem para mostrar ao usuário a partir de um erro qualquer.
String mensagemDeErro(Object erro) => erro is ErroApi
    ? erro.mensagem
    : 'Não foi possível falar com o servidor. Verifique sua conexão.';

/// SnackBar curta, substituindo a anterior.
void avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
}

/// Diálogo de confirmação; devolve `true` se o usuário confirmou.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String acao,
}) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(acao)),
      ],
    ),
  );
  return confirmou ?? false;
}

/// Campo de data que abre o calendário ao tocar, com botão para limpar.
class CampoData extends StatelessWidget {
  const CampoData({super.key, required this.rotulo, required this.data, this.aoEscolher, this.aoLimpar});

  final String rotulo;
  final DateTime? data;
  final VoidCallback? aoEscolher;
  final VoidCallback? aoLimpar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoEscolher,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: rotulo,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: data == null
              ? null
              : IconButton(tooltip: 'Limpar $rotulo', icon: const Icon(Icons.close), onPressed: aoLimpar),
        ),
        child: Text(data == null ? '—' : Datas.formatar(data!)),
      ),
    );
  }
}

/// Nota explicativa em destaque discreto, com ícone de informação.
class CaixaInfo extends StatelessWidget {
  const CaixaInfo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.primaria.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Cores.primaria),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Cores.tinta, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
