import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/rotas.dart';
import 'core/tema/tema.dart';
import 'features/areas/area_provisoria.dart';
import 'features/auth/domain/limitador_tentativas.dart';
import 'features/auth/presentation/login_controller.dart';
import 'features/auth/presentation/tela_boas_vindas.dart';
import 'features/auth/presentation/tela_login.dart';
import 'features/auth/presentation/tela_recuperar_senha.dart';
import 'features/beneficios/presentation/tela_beneficios.dart';
import 'features/painel_admin/tela_painel_admin.dart';
import 'features/planos/presentation/tela_planos.dart';
import 'repositorios.dart';

class MembroPassApp extends StatelessWidget {
  const MembroPassApp({super.key, required this.repositorios});

  final Repositorios repositorios;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...repositorios.providers,
        ChangeNotifierProvider(
          create: (_) => LoginController(repositorios.auth, LimitadorTentativas()),
        ),
      ],
      child: MaterialApp(
        title: 'MembroPass',
        debugShowCheckedModeBanner: false,
        theme: criarTema(),
        // Calendários e textos padrão do Flutter em português.
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: Rotas.boasVindas,
        routes: {
          Rotas.boasVindas: (_) => const TelaBoasVindas(),
          Rotas.login: (_) => const TelaLogin(),
          Rotas.recuperarSenha: (context) => TelaRecuperarSenha(
                emailInicial: ModalRoute.of(context)?.settings.arguments as String? ?? '',
              ),
          Rotas.areaAdministrador: (_) => const TelaPainelAdmin(),
          Rotas.planos: (_) => const TelaPlanos(),
          Rotas.beneficios: (_) => const TelaBeneficios(),
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
