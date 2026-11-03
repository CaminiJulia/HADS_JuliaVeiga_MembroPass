import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
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
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
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
