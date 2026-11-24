import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/validacao/validadores.dart';
import '../../../core/widgets/componentes.dart';
import '../domain/operador.dart';

/// Cadastra um operador novo (fecha devolvendo [OperadorCriado]) ou edita
/// [operador] (fecha devolvendo o [Operador] salvo).
class TelaFormularioOperador extends StatefulWidget {
  const TelaFormularioOperador({super.key, this.operador});

  final Operador? operador;

  @override
  State<TelaFormularioOperador> createState() => _TelaFormularioOperadorState();
}

class _TelaFormularioOperadorState extends State<TelaFormularioOperador> {
  final _formulario = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.operador?.nome);
  late final _email = TextEditingController(text: widget.operador?.email);
  late final _telefone = TextEditingController(text: widget.operador?.telefone);
  bool _salvando = false;

  bool get _novo => widget.operador == null;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);
    final telefone = _telefone.text.trim();
    final dados = DadosOperador(
      nome: _nome.text.trim(),
      email: _email.text.trim().toLowerCase(),
      telefone: telefone.isEmpty ? null : telefone,
    );
    try {
      final repositorio = context.read<OperadoresRepositorio>();
      final Object salvo = _novo
          ? await repositorio.criar(dados)
          : await repositorio.editar(widget.operador!.id, dados);
      if (mounted) Navigator.of(context).pop(salvo);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        avisar(context, mensagemDeErro(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_novo ? 'Novo operador' : 'Editar operador')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: FilledButton(
            key: const Key('botao-salvar-operador'),
            onPressed: _salvando ? null : _salvar,
            child: _salvando ? const CarregandoBotao() : Text(_novo ? 'Cadastrar operador' : 'Salvar alterações'),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formulario,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                TextFormField(
                  key: const Key('campo-nome-operador'),
                  controller: _nome,
                  enabled: !_salvando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                    counterText: '',
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome do operador.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('campo-email-operador'),
                  controller: _email,
                  enabled: !_salvando,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'E-mail de acesso',
                    prefixIcon: Icon(Icons.mail_outline),
                    helperText: 'É com este e-mail que o operador entra no app.',
                  ),
                  validator: (v) => Validadores.email(v)?.replaceFirst('seu e-mail', 'o e-mail'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('campo-telefone-operador'),
                  controller: _telefone,
                  enabled: !_salvando,
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Celular (opcional)',
                    hintText: '(54) 99999-0000',
                    prefixIcon: Icon(Icons.phone_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    return t.isEmpty || RegExp(r'^[\d\s()+-]{8,20}$').hasMatch(t)
                        ? null
                        : 'Informe um telefone válido.';
                  },
                ),
                if (_novo) ...[
                  const SizedBox(height: 20),
                  const CaixaInfo(
                    'Ao cadastrar, geramos uma senha provisória para você repassar. '
                    'O operador pode trocá-la em "Meu perfil", no app.',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
