import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/rotas.dart';
import '../domain/auth_repositorio.dart';

/// Encerra a sessão e volta às boas-vindas, limpando a pilha de telas
/// para o botão voltar não reabrir uma área logada.
void sairDaConta(BuildContext context) {
  context.read<AuthRepositorio>().sair();
  Navigator.of(context).pushNamedAndRemoveUntil(Rotas.boasVindas, (_) => false);
}
