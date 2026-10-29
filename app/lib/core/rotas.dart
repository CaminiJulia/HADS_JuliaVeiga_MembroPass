import '../features/auth/domain/papel.dart';

abstract final class Rotas {
  static const login = '/';
  static const recuperarSenha = '/recuperar-senha';
  static const areaAdministrador = '/administrador';
  static const areaOperador = '/operador';
  static const areaMembro = '/membro';

  /// Área inicial de cada papel após o login (RF01).
  static String inicialDo(Papel papel) => switch (papel) {
        Papel.administrador => areaAdministrador,
        Papel.operador => areaOperador,
        Papel.membro => areaMembro,
      };
}
