import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/tema/cores.dart';
import '../../../core/validacao/validadores.dart';
import '../domain/auth_repositorio.dart';
import 'widgets/aviso_erro.dart';

/// HU03 — Recuperar senha.
class TelaRecuperarSenha extends StatefulWidget {
  const TelaRecuperarSenha({super.key, this.emailInicial = ''});

  final String emailInicial;

  @override
  State<TelaRecuperarSenha> createState() => _TelaRecuperarSenhaState();
}

class _TelaRecuperarSenhaState extends State<TelaRecuperarSenha> {
  final _formulario = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.emailInicial);
  bool _enviando = false;
  bool _enviado = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await context.read<AuthRepositorio>().solicitarRecuperacaoSenha(_email.text.trim());
      if (mounted) setState(() => _enviado = true);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível enviar agora. Tente novamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _enviado ? _confirmacao(texto) : _formularioEnvio(texto),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formularioEnvio(TextTheme texto) {
    return Form(
      key: _formulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recuperar senha',
            style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta),
          ),
          const SizedBox(height: 8),
          Text(
            'Informe o e-mail do seu cadastro. Enviaremos um link para você criar uma nova senha.',
            style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
          ),
          const SizedBox(height: 24),
          if (_erro != null) ...[
            AvisoErro(mensagem: _erro!),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _email,
            enabled: !_enviando,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: Validadores.email,
            onFieldSubmitted: (_) => _enviar(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Enviar link'),
          ),
        ],
      ),
    );
  }

  Widget _confirmacao(TextTheme texto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 56, color: Cores.primaria),
        const SizedBox(height: 16),
        Text(
          'Verifique seu e-mail',
          textAlign: TextAlign.center,
          style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta),
        ),
        const SizedBox(height: 8),
        // Mesma mensagem exista ou não o cadastro, para não revelar quais e-mails estão na base.
        Text(
          'Se ${_email.text.trim()} estiver cadastrado, você receberá em instantes um link '
          'temporário para redefinir sua senha.',
          textAlign: TextAlign.center,
          style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar ao login'),
        ),
      ],
    );
  }
}
