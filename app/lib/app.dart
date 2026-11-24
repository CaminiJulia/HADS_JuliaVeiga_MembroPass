import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/rotas.dart';
import 'core/tema/tema.dart';
import 'features/area_membro/presentation/tela_area_membro.dart';
import 'features/area_operador/presentation/leitor_qr.dart';
import 'features/area_operador/presentation/tela_area_operador.dart';
import 'features/auditoria/presentation/tela_auditoria.dart';
import 'features/auth/domain/limitador_tentativas.dart';
import 'features/auth/presentation/login_controller.dart';
import 'features/auth/presentation/tela_boas_vindas.dart';
import 'features/auth/presentation/tela_login.dart';
import 'features/auth/presentation/tela_recuperar_senha.dart';
import 'features/beneficios/presentation/tela_beneficios.dart';
import 'features/identidade/presentation/tela_identidade.dart';
import 'features/membros/presentation/tela_membros.dart';
import 'features/operadores/presentation/tela_operadores.dart';
import 'features/painel_admin/tela_painel_admin.dart';
import 'features/perfil/presentation/tela_perfil.dart';
import 'features/planos/presentation/tela_planos.dart';
import 'features/unidades/presentation/tela_unidades.dart';
import 'repositorios.dart';

class MembroPassApp extends StatelessWidget {
  const MembroPassApp({super.key, required this.repositorios, this.leitorQr = const LeitorQrCamera()});

  final Repositorios repositorios;

  /// Câmera do check-in; os testes usam um leitor simulado.
  final LeitorQr leitorQr;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...repositorios.providers,
        Provider<LeitorQr>.value(value: leitorQr),
        ChangeNotifierProvider(create: (_) => LoginController(repositorios.auth, LimitadorTentativas())),
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
          Rotas.recuperarSenha: (context) =>
              TelaRecuperarSenha(emailInicial: ModalRoute.of(context)?.settings.arguments as String? ?? ''),
          Rotas.areaAdministrador: (_) => const TelaPainelAdmin(),
          Rotas.planos: (_) => const TelaPlanos(),
          Rotas.beneficios: (_) => const TelaBeneficios(),
          Rotas.membros: (_) => const TelaMembros(),
          // RF07: os membros que pedem atenção do administrador.
          Rotas.ciclos: (_) => const TelaMembros(titulo: 'Ciclos e bloqueios', filtroInicial: FiltroMembros.atencao),
          Rotas.auditoria: (_) => const TelaAuditoria(),
          Rotas.unidades: (_) => const TelaUnidades(),
          Rotas.operadores: (_) => const TelaOperadores(),
          Rotas.identidade: (_) => const TelaIdentidade(),
          Rotas.perfil: (_) => const TelaPerfil(),
          Rotas.areaOperador: (_) => const TelaAreaOperador(),
          Rotas.perfilOperador: (_) => const TelaPerfil(),
          Rotas.areaMembro: (_) => const TelaAreaMembro(),
        },
      ),
    );
  }
}
