import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/api/cliente_api.dart';
import 'features/auth/data/auth_repositorio_api.dart';
import 'features/auth/data/auth_repositorio_mock.dart';
import 'features/auth/domain/auth_repositorio.dart';
import 'features/beneficios/data/beneficios_repositorio_api.dart';
import 'features/beneficios/data/beneficios_repositorio_mock.dart';
import 'features/beneficios/domain/beneficios_repositorio.dart';
import 'features/planos/data/planos_repositorio_api.dart';
import 'features/planos/data/planos_repositorio_mock.dart';
import 'features/planos/domain/planos_repositorio.dart';

/// Todos os repositórios do app, para trocar a API pelos simulados nos testes.
class Repositorios {
  const Repositorios({required this.auth, required this.planos, required this.beneficios});

  /// Implementações que falam com a API, compartilhando o mesmo token.
  factory Repositorios.api(ClienteApi api) => Repositorios(
        auth: AuthRepositorioApi(api),
        planos: PlanosRepositorioApi(api),
        beneficios: BeneficiosRepositorioApi(api),
      );

  /// Implementações em memória, para os testes.
  factory Repositorios.simulados() => Repositorios(
        auth: AuthRepositorioMock(latencia: Duration.zero),
        planos: PlanosRepositorioMock(),
        beneficios: BeneficiosRepositorioMock(),
      );

  final AuthRepositorio auth;
  final PlanosRepositorio planos;
  final BeneficiosRepositorio beneficios;

  List<SingleChildWidget> get providers => [
        Provider<AuthRepositorio>.value(value: auth),
        Provider<PlanosRepositorio>.value(value: planos),
        Provider<BeneficiosRepositorio>.value(value: beneficios),
      ];
}
