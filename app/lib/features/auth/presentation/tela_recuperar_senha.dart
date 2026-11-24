import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/tema/cores.dart';
import '../../../core/validacao/validadores.dart';
import '../../../core/widgets/componentes.dart';
import '../domain/auth_repositorio.dart';
import 'widgets/aviso_erro.dart';
import 'widgets/campos_nova_senha.dart';
import 'widgets/visual_entrada.dart';

enum _Etapa { email, codigo, concluido }

/// HU03 — Recuperar senha, em duas etapas: o e-mail recebe um código de 6
/// dígitos (vale 15 minutos) e, com ele, a pessoa cria uma senha nova.
class TelaRecuperarSenha extends StatefulWidget {
  const TelaRecuperarSenha({super.key, this.emailInicial = ''});

  final String emailInicial;

  @override
  State<TelaRecuperarSenha> createState() => _TelaRecuperarSenhaState();
}

class _TelaRecuperarSenhaState extends State<TelaRecuperarSenha> {
  final _formEmail = GlobalKey<FormState>();
  final _formCodigo = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.emailInicial);
  final _codigo = TextEditingController();
  final _nova = TextEditingController();
  var _etapa = _Etapa.email;
  bool _enviando = false;
  String? _erro;

  AuthRepositorio get _auth => context.read<AuthRepositorio>();

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    _nova.dispose();
    super.dispose();
  }

  /// Envia (ou reenvia) o código. A resposta é a mesma exista ou não o
  /// cadastro, para não revelar quais e-mails estão na base.
  Future<void> _enviarCodigo({bool reenvio = false}) async {
    if (!reenvio && !_formEmail.currentState!.validate()) return;
    await _executar(() async {
      await _auth.solicitarRecuperacaoSenha(_email.text.trim());
      if (!mounted) return;
      setState(() => _etapa = _Etapa.codigo);
      if (reenvio) avisar(context, 'Enviamos um novo código.');
    });
  }

  Future<void> _redefinir() async {
    if (!_formCodigo.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _executar(() async {
      await _auth.redefinirSenha(email: _email.text.trim(), codigo: _codigo.text, novaSenha: _nova.text);
      if (mounted) setState(() => _etapa = _Etapa.concluido);
    });
  }

  Future<void> _executar(Future<void> Function() acao) async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await acao();
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FundoEntrada(
      comVoltar: true,
      child: Builder(
        // Builder para ler o tema escuro aplicado pelo FundoEntrada.
        builder: (context) {
          final texto = Theme.of(context).textTheme;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 56, 28, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: switch (_etapa) {
                  _Etapa.email => _etapaEmail(texto),
                  _Etapa.codigo => _etapaCodigo(texto),
                  _Etapa.concluido => _concluido(texto),
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titulo(TextTheme texto, String titulo, String subtitulo) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        titulo,
        style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
      ),
      const SizedBox(height: 8),
      Text(subtitulo, style: texto.bodyMedium?.copyWith(color: Colors.white70, height: 1.4)),
      const SizedBox(height: 24),
      if (_erro != null) ...[AvisoErro(mensagem: _erro!), const SizedBox(height: 16)],
    ],
  );

  Widget _etapaEmail(TextTheme texto) {
    return Form(
      key: _formEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titulo(
            texto,
            'Recuperar senha',
            'Informe o e-mail do seu cadastro. Enviaremos um código para você criar uma nova senha.',
          ),
          TextFormField(
            key: const Key('campo-email-recuperar'),
            controller: _email,
            enabled: !_enviando,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
            validator: Validadores.email,
            onFieldSubmitted: (_) => _enviarCodigo(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('botao-enviar-codigo'),
            onPressed: _enviando ? null : _enviarCodigo,
            child: _enviando ? const CarregandoBotao() : const Text('Enviar código'),
          ),
        ],
      ),
    );
  }

  Widget _etapaCodigo(TextTheme texto) {
    return Form(
      key: _formCodigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titulo(
            texto,
            'Digite o código',
            // Mesma mensagem exista ou não o cadastro.
            'Se ${_email.text.trim()} estiver cadastrado, você vai receber um código de 6 números. '
                'Ele vale por 15 minutos. Confira também a caixa de spam.',
          ),
          TextFormField(
            key: const Key('campo-codigo'),
            controller: _codigo,
            enabled: !_enviando,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(labelText: 'Código', hintText: '000000'),
            validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'O código tem 6 números.',
          ),
          const SizedBox(height: 16),
          CamposNovaSenha(nova: _nova, habilitado: !_enviando, aoConcluir: _redefinir),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('botao-redefinir-senha'),
            onPressed: _enviando ? null : _redefinir,
            child: _enviando ? const CarregandoBotao() : const Text('Criar nova senha'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _enviando ? null : () => _enviarCodigo(reenvio: true),
            child: const Text('Não recebi: enviar outro código'),
          ),
        ],
      ),
    );
  }

  Widget _concluido(TextTheme texto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.verified_user_outlined, size: 56, color: Cores.sucesso),
        const SizedBox(height: 16),
        Text(
          'Senha alterada',
          textAlign: TextAlign.center,
          style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Entre com a nova senha. Por segurança, as sessões abertas em outros aparelhos foram encerradas.',
          textAlign: TextAlign.center,
          style: texto.bodyMedium?.copyWith(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('botao-voltar-login'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar ao login'),
        ),
      ],
    );
  }
}
