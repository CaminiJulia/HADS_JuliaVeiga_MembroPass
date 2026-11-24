import 'package:flutter/material.dart';

import '../../../../core/validacao/validadores.dart';

/// "Nova senha" e "Repita a nova senha", com o botão de mostrar. Usado no
/// primeiro acesso (senha provisória) e na recuperação de senha.
/// Precisa estar dentro de um [Form].
class CamposNovaSenha extends StatefulWidget {
  const CamposNovaSenha({super.key, required this.nova, this.habilitado = true, this.aoConcluir});

  final TextEditingController nova;
  final bool habilitado;

  /// Enter no último campo.
  final VoidCallback? aoConcluir;

  @override
  State<CamposNovaSenha> createState() => _CamposNovaSenhaState();
}

class _CamposNovaSenhaState extends State<CamposNovaSenha> {
  final _confirmacao = TextEditingController();
  bool _visivel = false;

  @override
  void dispose() {
    _confirmacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mostrar = IconButton(
      tooltip: _visivel ? 'Ocultar senhas' : 'Mostrar senhas',
      icon: Icon(_visivel ? Icons.visibility_off_outlined : Icons.visibility_outlined),
      onPressed: () => setState(() => _visivel = !_visivel),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('campo-nova-senha'),
          controller: widget.nova,
          enabled: widget.habilitado,
          obscureText: !_visivel,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Nova senha',
            helperText: 'Mínimo de 8 caracteres, com letras e números.',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: mostrar,
          ),
          validator: Validadores.novaSenha,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('campo-confirmar-senha'),
          controller: _confirmacao,
          enabled: widget.habilitado,
          obscureText: !_visivel,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => widget.aoConcluir?.call(),
          decoration: const InputDecoration(labelText: 'Repita a nova senha', prefixIcon: Icon(Icons.lock_outline)),
          validator: (v) => v != widget.nova.text ? 'As senhas não conferem.' : null,
        ),
      ],
    );
  }
}
