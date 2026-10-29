import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/rotas.dart';
import 'core/tema/tema.dart';
import 'features/areas/area_provisoria.dart';
import 'features/auth/domain/auth_repositorio.dart';
import 'features/auth/domain/limitador_tentativas.dart';
import 'features/auth/presentation/login_controller.dart';
import 'features/auth/presentation/tela_login.dart';
import 'features/auth/presentation/tela_recuperar_senha.dart';

class MembroPassApp extends StatelessWidget {
  const MembroPassApp({super.key, required this.authRepositorio});

  final AuthRepositorio authRepositorio;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepositorio>.value(value: authRepositorio),
        ChangeNotifierProvider(
          create: (_) => LoginController(authRepositorio, LimitadorTentativas()),
        ),
      ],
      child: MaterialApp(
        title: 'MembroPass',
        debugShowCheckedModeBanner: false,
        theme: criarTema(),
        initialRoute: Rotas.login,
        routes: {
          Rotas.login: (_) => const TelaLogin(),
          Rotas.recuperarSenha: (context) => TelaRecuperarSenha(
                emailInicial: ModalRoute.of(context)?.settings.arguments as String? ?? '',
              ),
          Rotas.areaAdministrador: (_) => const AreaProvisoria(
                titulo: 'Painel da organização',
                descricao: 'Aqui ficará o painel do administrador da organização.',
                icone: Icons.dashboard_outlined,
              ),
          Rotas.areaOperador: (_) => const AreaProvisoria(
                titulo: 'Validar check-in',
                descricao: 'Aqui ficará a leitura de QR Code do operador.',
                icone: Icons.qr_code_scanner,
              ),
          Rotas.areaMembro: (_) => const AreaProvisoria(
                titulo: 'Minha carteirinha',
                descricao: 'Aqui ficará a carteirinha digital do membro.',
                icone: Icons.badge_outlined,
              ),
        },
      ),
    );
  }
}
