import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'areas/area_administrador.dart';
import 'areas/area_membro.dart';
import 'areas/area_operador.dart';
import 'auth/sessao.dart';
import 'auth/tela_login.dart';
import 'auth/usuario.dart';
import 'tema.dart';

void main() {
  runApp(const ProviderScope(child: MembroPassApp()));
}

class MembroPassApp extends ConsumerWidget {
  const MembroPassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(sessaoProvider);
    final usuario = sessao.value;

    return MaterialApp(
      title: 'MembroPass',
      debugShowCheckedModeBanner: false,
      // Depois do login, o app assume a cor da organização (white-label, RF17).
      theme: temaDaOrganizacao(usuario?.organizacao.corPrincipal),
      home: sessao.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : switch (usuario?.papel) {
              null => const TelaLogin(),
              Papel.administrador => AreaAdministrador(usuario: usuario!),
              Papel.operador => AreaOperador(usuario: usuario!),
              Papel.membro => AreaMembro(usuario: usuario!),
            },
    );
  }
}
