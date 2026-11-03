import '../features/auth/domain/papel.dart';

abstract final class Rotas {
  static const boasVindas = '/';
  static const login = '/login';
  static const recuperarSenha = '/recuperar-senha';
  static const areaAdministrador = '/administrador';
  static const areaOperador = '/operador';
  static const areaMembro = '/membro';
  static const planos = '/administrador/planos';
  static const beneficios = '/administrador/beneficios';
  static const membros = '/administrador/membros';
  static const ciclos = '/administrador/ciclos';
  static const auditoria = '/administrador/auditoria';
  static const unidades = '/administrador/unidades';

  /// Área inicial de cada papel após o login (RF01).
  static String inicialDo(Papel papel) => switch (papel) {
        Papel.administrador => areaAdministrador,
        Papel.operador => areaOperador,
        Papel.membro => areaMembro,
      };
}
