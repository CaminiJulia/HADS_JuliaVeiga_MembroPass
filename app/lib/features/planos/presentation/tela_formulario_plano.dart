import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/moeda.dart';
import '../../../core/widgets/componentes.dart';
import '../../auth/presentation/widgets/aviso_erro.dart';
import '../domain/plano.dart';
import '../domain/planos_repositorio.dart';

/// Cria um plano novo ou edita [plano]. Fecha devolvendo o plano salvo.
class TelaFormularioPlano extends StatefulWidget {
  const TelaFormularioPlano({super.key, this.plano});

  final Plano? plano;

  @override
  State<TelaFormularioPlano> createState() => _TelaFormularioPlanoState();
}

class _TelaFormularioPlanoState extends State<TelaFormularioPlano> {
  final _formulario = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.plano?.nome);
  late final _valor = TextEditingController(
    text: widget.plano == null ? null : Moeda.paraCampo(widget.plano!.valorReferencia),
  );
  late final _duracao = TextEditingController(text: widget.plano?.duracaoDias.toString());

  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.plano != null;

  @override
  void dispose() {
    _nome.dispose();
    _valor.dispose();
    _duracao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _salvando = true;
      _erro = null;
    });

    final dados = DadosPlano(
      nome: _nome.text.trim(),
      valorReferencia: Moeda.ler(_valor.text)!,
      duracaoDias: int.parse(_duracao.text),
    );
    final repositorio = context.read<PlanosRepositorio>();
    try {
      final salvo = _editando
          ? await repositorio.editar(widget.plano!.id, dados)
          : await repositorio.criar(dados);
      if (mounted) Navigator.of(context).pop(salvo);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = mensagemDeErro(e);
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar plano' : 'Novo plano')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_erro != null) ...[
                      AvisoErro(mensagem: _erro!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const Key('campo-nome-plano'),
                      controller: _nome,
                      enabled: !_salvando,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Nome do plano',
                        hintText: 'Ex.: Mensal, Família, Estudante',
                        counterText: '',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome do plano.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo-valor-plano'),
                      controller: _valor,
                      enabled: !_salvando,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                      decoration: const InputDecoration(
                        labelText: 'Valor de referência',
                        prefixText: 'R\$ ',
                        hintText: '0,00',
                      ),
                      validator: (v) => Moeda.ler(v ?? '') == null ? 'Informe um valor válido, ex.: 89,90.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo-duracao-plano'),
                      controller: _duracao,
                      enabled: !_salvando,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Duração do ciclo',
                        suffixText: 'dias',
                        hintText: '30',
                      ),
                      validator: (v) {
                        final dias = int.tryParse(v ?? '');
                        if (dias == null || dias < 1) return 'Informe pelo menos 1 dia.';
                        if (dias > 3650) return 'O máximo é 3650 dias.';
                        return null;
                      },
                      onFieldSubmitted: (_) => _salvar(),
                    ),
                    const SizedBox(height: 16),
                    const CaixaInfo(
                      'O pagamento é combinado fora do app. O valor serve de referência, e a duração '
                      'define o novo vencimento quando você confirmar um pagamento.',
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('botao-salvar-plano'),
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando
                          ? const CarregandoBotao()
                          : Text(_editando ? 'Salvar alterações' : 'Criar plano'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
