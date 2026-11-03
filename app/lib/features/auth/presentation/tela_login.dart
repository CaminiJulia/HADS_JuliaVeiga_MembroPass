import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/rotas.dart';
import '../../../core/validacao/validadores.dart';
import 'login_controller.dart';
import 'widgets/aviso_erro.dart';
import 'widgets/visual_entrada.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final controller = context.read<LoginController>();
    if (controller.carregando) return;
    if (!_formulario.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final usuario = await controller.entrar(_email.text, _senha.text);
    if (usuario == null || !mounted) return;

    TextInput.finishAutofillContext();
    // Limpa a pilha: o botão voltar não deve retornar ao login nem às boas-vindas.
    Navigator.of(context).pushNamedAndRemoveUntil(
      Rotas.inicialDo(usuario.papel),
      (_) => false,
      arguments: usuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();

    return FundoEntrada(
      comVoltar: Navigator.of(context).canPop(),
      child: Builder(
        // Builder para ler o tema escuro aplicado pelo FundoEntrada.
        builder: (context) {
          final texto = Theme.of(context).textTheme;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 56, 28, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formulario,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SvgPicture.asset(
                            'assets/marca/icone.svg',
                            width: 52,
                            semanticsLabel: 'MembroPass',
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Acesse sua conta',
                          style: texto.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use o e-mail e a senha do seu cadastro.',
                          style: texto.bodyMedium?.copyWith(color: Colors.white70, height: 1.4),
                        ),
                        const SizedBox(height: 32),
                        if (controller.erro != null) ...[
                          AvisoErro(mensagem: controller.erro!),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          key: const Key('campo-email'),
                          controller: _email,
                          enabled: !controller.carregando,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: Validadores.email,
                          onChanged: (_) => controller.limparErro(),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const Key('campo-senha'),
                          controller: _senha,
                          enabled: !controller.carregando,
                          obscureText: !_senhaVisivel,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                              icon: Icon(
                                _senhaVisivel
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _senhaVisivel = !_senhaVisivel),
                            ),
                          ),
                          validator: Validadores.senha,
                          onChanged: (_) => controller.limparErro(),
                          onFieldSubmitted: (_) => _entrar(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: controller.carregando
                                ? null
                                : () => Navigator.of(context).pushNamed(
                                      Rotas.recuperarSenha,
                                      arguments: _email.text.trim(),
                                    ),
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const Key('botao-entrar'),
                          onPressed: controller.carregando ? null : _entrar,
                          child: controller.carregando
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ainda não tem acesso? Peça o link de adesão à sua organização.',
                          textAlign: TextAlign.center,
                          style: texto.bodySmall?.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
