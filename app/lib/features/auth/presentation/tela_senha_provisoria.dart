import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/rotas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../domain/auth_repositorio.dart';
import '../domain/usuario.dart';
import 'sair.dart';
import 'widgets/aviso_erro.dart';
import 'widgets/campos_nova_senha.dart';
import 'widgets/visual_entrada.dart';

/// Primeiro acesso com a senha provisória gerada pelo administrador: antes
/// de abrir a área, a pessoa cria uma senha só dela.
class TelaSenhaProvisoria extends StatefulWidget {
  const TelaSenhaProvisoria({super.key, required this.usuario, required this.senhaProvisoria});

  final Usuario usuario;

  /// A senha que acabou de ser digitada no login (é a "senha atual").
  final String senhaProvisoria;

  @override
  State<TelaSenhaProvisoria> createState() => _TelaSenhaProvisoriaState();
}

class _TelaSenhaProvisoriaState extends State<TelaSenhaProvisoria> {
  final _formulario = GlobalKey<FormState>();
  final _nova = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nova.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _erro = null);
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);
    try {
      await context.read<AuthRepositorio>().trocarSenha(senhaAtual: widget.senhaProvisoria, novaSenha: _nova.text);
      if (!mounted) return;
      final usuario = widget.usuario;
      Navigator.of(context).pushNamedAndRemoveUntil(Rotas.inicialDo(usuario.papel), (_) => false, arguments: usuario);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primeiroNome = widget.usuario.nome.split(' ').first;
    return FundoEntrada(
      child: Builder(
        builder: (context) {
          final texto = Theme.of(context).textTheme;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 56, 28, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formulario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.key_outlined, size: 48, color: Cores.lilas),
                      const SizedBox(height: 16),
                      Text(
                        'Crie sua senha, $primeiroNome',
                        style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Você entrou com a senha provisória que recebeu de ${widget.usuario.organizacaoNome}. '
                        'Para continuar, escolha uma senha só sua.',
                        style: texto.bodyMedium?.copyWith(color: Colors.white70, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      if (_erro != null) ...[AvisoErro(mensagem: _erro!), const SizedBox(height: 16)],
                      CamposNovaSenha(nova: _nova, habilitado: !_salvando, aoConcluir: _salvar),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('botao-criar-senha'),
                        onPressed: _salvando ? null : _salvar,
                        child: _salvando ? const CarregandoBotao() : const Text('Salvar e continuar'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _salvando ? null : () => sairDaConta(context), child: const Text('Sair')),
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
