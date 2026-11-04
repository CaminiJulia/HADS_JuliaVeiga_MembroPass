import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/api/cliente_api.dart';
import 'features/auditoria/data/auditoria_repositorio_api.dart';
import 'features/auditoria/domain/registro_auditoria.dart';
import 'features/auth/data/auth_repositorio_api.dart';
import 'features/auth/data/auth_repositorio_mock.dart';
import 'features/auth/domain/auth_repositorio.dart';
import 'features/beneficios/data/beneficios_repositorio_api.dart';
import 'features/beneficios/data/beneficios_repositorio_mock.dart';
import 'features/beneficios/domain/beneficios_repositorio.dart';
import 'features/identidade/data/organizacao_repositorio.dart';
import 'features/identidade/domain/organizacao.dart';
import 'features/membros/data/membros_repositorio_api.dart';
import 'features/membros/data/membros_repositorio_mock.dart';
import 'features/membros/domain/membros_repositorio.dart';
import 'features/perfil/data/perfil_repositorio.dart';
import 'features/perfil/domain/perfil.dart';
import 'features/planos/data/planos_repositorio_api.dart';
import 'features/planos/data/planos_repositorio_mock.dart';
import 'features/planos/domain/planos_repositorio.dart';
import 'features/unidades/data/unidades_repositorio_api.dart';
import 'features/unidades/data/unidades_repositorio_mock.dart';
import 'features/unidades/domain/unidade_evento.dart';

/// Todos os repositórios do app, para trocar a API pelos simulados nos testes.
class Repositorios {
  const Repositorios({
    required this.auth,
    required this.planos,
    required this.beneficios,
    required this.membros,
    required this.auditoria,
    required this.unidades,
    required this.organizacao,
    required this.perfil,
  });

  /// Implementações que falam com a API, compartilhando o mesmo token.
  factory Repositorios.api(ClienteApi api) => Repositorios(
        auth: AuthRepositorioApi(api),
        planos: PlanosRepositorioApi(api),
        beneficios: BeneficiosRepositorioApi(api),
        membros: MembrosRepositorioApi(api),
        auditoria: AuditoriaRepositorioApi(api),
        unidades: UnidadesRepositorioApi(api),
        organizacao: OrganizacaoRepositorioApi(api),
        perfil: PerfilRepositorioApi(api),
      );

  /// Implementações em memória, para os testes.
  factory Repositorios.simulados() {
    final membros = MembrosRepositorioMock();
    return Repositorios(
      auth: AuthRepositorioMock(latencia: Duration.zero),
      planos: PlanosRepositorioMock(),
      beneficios: BeneficiosRepositorioMock(),
      membros: membros,
      auditoria: AuditoriaRepositorioMock(membros),
      unidades: UnidadesRepositorioMock(),
      organizacao: OrganizacaoRepositorioMock(),
      perfil: PerfilRepositorioMock(),
    );
  }

  final AuthRepositorio auth;
  final PlanosRepositorio planos;
  final BeneficiosRepositorio beneficios;
  final MembrosRepositorio membros;
  final AuditoriaRepositorio auditoria;
  final UnidadesRepositorio unidades;
  final OrganizacaoRepositorio organizacao;
  final PerfilRepositorio perfil;

  List<SingleChildWidget> get providers => [
        Provider<AuthRepositorio>.value(value: auth),
        Provider<PlanosRepositorio>.value(value: planos),
        Provider<BeneficiosRepositorio>.value(value: beneficios),
        Provider<MembrosRepositorio>.value(value: membros),
        Provider<AuditoriaRepositorio>.value(value: auditoria),
        Provider<UnidadesRepositorio>.value(value: unidades),
        Provider<OrganizacaoRepositorio>.value(value: organizacao),
        Provider<PerfilRepositorio>.value(value: perfil),
      ];
}
