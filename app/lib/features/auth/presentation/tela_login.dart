import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/rotas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/validacao/validadores.dart';
import 'login_controller.dart';
import 'widgets/aviso_erro.dart';

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
    Navigator.of(context).pushReplacementNamed(
      Rotas.inicialDo(usuario.papel),
      arguments: usuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SvgPicture.asset(
                    'assets/marca/icone.svg',
                    height: 72,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(height: 16),
                  SvgPicture.asset(
                    'assets/marca/nome-fundo-claro.svg',
                    height: 30,
                    semanticsLabel: 'MembroPass',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sua carteirinha digital de associado',
                    textAlign: TextAlign.center,
                    style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
                  ),
                  const SizedBox(height: 32),
                  _CartaoFormulario(
                    child: Form(
                      key: _formulario,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Entrar',
                              style: texto.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Cores.tinta,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use o e-mail e a senha do seu cadastro.',
                              style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
                            ),
                            const SizedBox(height: 24),
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
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 8),
                            FilledButton(
                              key: const Key('botao-entrar'),
                              onPressed: controller.carregando ? null : _entrar,
                              child: controller.carregando
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ainda não tem acesso? Peça o link de adesão à sua organização.',
                    textAlign: TextAlign.center,
                    style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoFormulario extends StatelessWidget {
  const _CartaoFormulario({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Cores.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Cores.borda),
        boxShadow: [
          BoxShadow(
            color: Cores.tinta.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
