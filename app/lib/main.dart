import 'package:flutter/material.dart';

import 'areas/area_provisoria.dart';
import 'auth/auth_repositorio.dart';
import 'auth/auth_repositorio_simulado.dart';
import 'auth/tela_boas_vindas.dart';
import 'auth/tela_login.dart';
import 'auth/usuario.dart';
import 'tema.dart';

void main() {
  runApp(MembroPassApp(repositorio: AuthRepositorioSimulado()));
}

class MembroPassApp extends StatelessWidget {
  const MembroPassApp({super.key, required this.repositorio});

  final AuthRepositorio repositorio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MembroPass',
      debugShowCheckedModeBanner: false,
      theme: criarTema(),
      home: Builder(builder: _boasVindas),
    );
  }

  Widget _boasVindas(BuildContext context) {
    return TelaBoasVindas(
      aoEntrarComEmail: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => TelaLogin(repositorio: repositorio, aoEntrar: (u) => _abrirArea(context, u))),
      ),
    );
  }

  /// Troca a pilha inteira pela área do papel: o botão voltar não retorna ao login.
  void _abrirArea(BuildContext context, Usuario usuario) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => AreaProvisoria(
          usuario: usuario,
          aoSair: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: _boasVindas),
            (_) => false,
          ),
        ),
      ),
      (_) => false,
    );
  }
}
