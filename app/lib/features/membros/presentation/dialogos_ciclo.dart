import 'package:flutter/material.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../domain/membro.dart';

/// RF07: pergunta a data em que o membro pagou, mostrando o novo vencimento.
/// Devolve a data escolhida, ou `null` se o administrador cancelar.
Future<DateTime?> pedirDataPagamento(BuildContext context, Membro membro) {
  return showDialog<DateTime>(context: context, builder: (_) => _DialogoPagamento(membro));
}

class _DialogoPagamento extends StatefulWidget {
  const _DialogoPagamento(this.membro);

  final Membro membro;

  @override
  State<_DialogoPagamento> createState() => _DialogoPagamentoState();
}

class _DialogoPagamentoState extends State<_DialogoPagamento> {
  late DateTime _data = Datas.hoje();

  Future<void> _escolher() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: Datas.hoje().subtract(const Duration(days: 365)),
      lastDate: Datas.hoje(),
      helpText: 'Data do pagamento',
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final membro = widget.membro;

    return AlertDialog(
      title: const Text('Confirmar pagamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirme só depois de receber o pagamento de ${membro.nome}. '
            'O app não faz cobranças.',
            style: texto.bodyMedium,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _escolher,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data do pagamento',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              child: Text(Datas.formatar(_data)),
            ),
          ),
          const SizedBox(height: 16),
          _Resumo('Plano', '${membro.planoNome} (${membro.planoDuracaoDias} dias)'),
          _Resumo('Vencimento atual', Datas.formatar(membro.carteirinha.dataVencimento)),
          _Resumo('Novo vencimento', Datas.formatar(membro.novoVencimento(_data)), destaque: true),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('botao-confirmar-dialogo-pagamento'),
          onPressed: () => Navigator.pop(context, _data),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo(this.rotulo, this.valor, {this.destaque = false});

  final String rotulo;
  final String valor;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(rotulo, style: estilo?.copyWith(color: Cores.textoSecundario))),
          Text(
            valor,
            style: estilo?.copyWith(
              fontWeight: destaque ? FontWeight.w800 : FontWeight.w500,
              color: destaque ? Cores.sucesso : Cores.tinta,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pede uma justificativa. Devolve o texto (vazio se não for [obrigatoria] e
/// ficar em branco), ou `null` se o administrador cancelar.
Future<String?> pedirJustificativa(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String rotulo,
  required String acao,
  required bool obrigatoria,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DialogoJustificativa(
      titulo: titulo,
      mensagem: mensagem,
      rotulo: rotulo,
      acao: acao,
      obrigatoria: obrigatoria,
    ),
  );
}

class _DialogoJustificativa extends StatefulWidget {
  const _DialogoJustificativa({
    required this.titulo,
    required this.mensagem,
    required this.rotulo,
    required this.acao,
    required this.obrigatoria,
  });

  final String titulo;
  final String mensagem;
  final String rotulo;
  final String acao;
  final bool obrigatoria;

  @override
  State<_DialogoJustificativa> createState() => _DialogoJustificativaState();
}

class _DialogoJustificativaState extends State<_DialogoJustificativa> {
  final _formulario = GlobalKey<FormState>();
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.mensagem),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('campo-justificativa'),
              controller: _texto,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: widget.rotulo),
              validator: (v) =>
                  widget.obrigatoria && (v ?? '').trim().isEmpty ? 'Informe o motivo.' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Cores.erro),
          onPressed: () {
            if (_formulario.currentState!.validate()) Navigator.pop(context, _texto.text.trim());
          },
          child: Text(widget.acao),
        ),
      ],
    );
  }
}
