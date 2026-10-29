import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/validadores.dart';
import 'auth_repositorio.dart';
import 'usuario.dart';
import 'visual_entrada.dart';

/// Tela de login única para os três papéis (RF01, HU02).
/// Depois de autenticar, chama [aoEntrar] com o usuário, e quem montou a tela
/// decide para qual área ele vai.
class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key, required this.repositorio, required this.aoEntrar});

  final AuthRepositorio repositorio;
  final void Function(Usuario usuario) aoEntrar;

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  bool _carregando = false;
  bool _senhaVisivel = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_carregando) return;
    setState(() => _erro = null);
    if (!_formulario.currentState!.validate()) return;

    setState(() => _carregando = true);
    try {
      final usuario = await widget.repositorio.entrar(email: _email.text.trim(), senha: _senha.text);
      if (!mounted) return;
      widget.aoEntrar(usuario);
    } on ErroLogin catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _esqueciSenha() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A recuperação de senha chega em uma próxima etapa.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FundoEntrada(
      comVoltar: Navigator.of(context).canPop(),
      child: Builder(
        // Builder para ler o tema escuro aplicado pelo FundoEntrada.
        builder: (context) {
          final textos = Theme.of(context).textTheme;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 56, 28, 24),
              child: ConstrainedBox(
                // Em tablet o formulário não estica pela tela toda (RNF13).
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formulario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SvgPicture.asset('assets/marca/membropass-icone.svg', width: 52, semanticsLabel: 'MembroPass'),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Acesse sua conta',
                        style: textos.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entre para ver sua carteirinha, validar check-ins ou gerenciar sua organização.',
                        style: textos.bodyMedium?.copyWith(color: Colors.white70, height: 1.4),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        key: const Key('campo-email'),
                        controller: _email,
                        enabled: !_carregando,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
                        validator: Validadores.email,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('campo-senha'),
                        controller: _senha,
                        enabled: !_carregando,
                        obscureText: !_senhaVisivel,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _entrar(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                            icon: Icon(_senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),
                        validator: (valor) => Validadores.obrigatorio(valor, campo: 'sua senha'),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _carregando ? null : _esqueciSenha,
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_erro != null) ...[
                        _MensagemErro(_erro!),
                        const SizedBox(height: 16),
                      ],
                      FilledButton(
                        key: const Key('botao-entrar'),
                        onPressed: _carregando ? null : _entrar,
                        child: _carregando
                            ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : const Text('Entrar'),
                      ),
                    ],
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

class _MensagemErro extends StatelessWidget {
  const _MensagemErro(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cores.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cores.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: cores.error),
            const SizedBox(width: 12),
            Expanded(child: Text(texto, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
