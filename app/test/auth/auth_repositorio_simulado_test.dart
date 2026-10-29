import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/auth/auth_repositorio.dart';
import 'package:membropass/auth/auth_repositorio_simulado.dart';
import 'package:membropass/auth/usuario.dart';

void main() {
  var agora = DateTime(2026, 10, 28, 10);

  AuthRepositorioSimulado criar() => AuthRepositorioSimulado(atraso: Duration.zero, relogio: () => agora);

  setUp(() => agora = DateTime(2026, 10, 28, 10));

  test('cada conta de teste entra com o seu papel (RF01)', () async {
    final repo = criar();
    for (final (email, papel) in [
      ('admin@membropass.dev', Papel.administrador),
      ('operador@membropass.dev', Papel.operador),
      ('membro@membropass.dev', Papel.membro),
    ]) {
      final usuario = await repo.entrar(email: email, senha: AuthRepositorioSimulado.senhaDeTeste);
      expect(usuario.papel, papel);
    }
  });

  test('e-mail não diferencia maiúsculas', () async {
    final usuario = await criar().entrar(email: 'Membro@MembroPass.dev', senha: AuthRepositorioSimulado.senhaDeTeste);
    expect(usuario.papel, Papel.membro);
  });

  test('senha errada e e-mail desconhecido dão o mesmo erro, sem revelar qual falhou', () async {
    final repo = criar();
    await expectLater(repo.entrar(email: 'membro@membropass.dev', senha: 'errada'), throwsA(isA<CredenciaisInvalidas>()));
    await expectLater(
      repo.entrar(email: 'ninguem@membropass.dev', senha: AuthRepositorioSimulado.senhaDeTeste),
      throwsA(isA<CredenciaisInvalidas>()),
    );
  });

  test('bloqueia após 5 tentativas inválidas, mesmo com a senha certa depois (RF01)', () async {
    final repo = criar();
    const email = 'membro@membropass.dev';
    for (var i = 0; i < 4; i++) {
      await expectLater(repo.entrar(email: email, senha: 'errada'), throwsA(isA<CredenciaisInvalidas>()));
    }
    await expectLater(repo.entrar(email: email, senha: 'errada'), throwsA(isA<AcessoBloqueado>()));
    await expectLater(
      repo.entrar(email: email, senha: AuthRepositorioSimulado.senhaDeTeste),
      throwsA(isA<AcessoBloqueado>()),
    );
  });

  test('libera de novo quando o tempo de bloqueio passa', () async {
    final repo = criar();
    const email = 'membro@membropass.dev';
    for (var i = 0; i < 5; i++) {
      await expectLater(repo.entrar(email: email, senha: 'errada'), throwsA(isA<ErroLogin>()));
    }

    agora = agora.add(const Duration(minutes: 15, seconds: 1));
    final usuario = await repo.entrar(email: email, senha: AuthRepositorioSimulado.senhaDeTeste);
    expect(usuario.email, email);
  });

  test('login certo zera a contagem de falhas', () async {
    final repo = criar();
    const email = 'membro@membropass.dev';
    for (var i = 0; i < 4; i++) {
      await expectLater(repo.entrar(email: email, senha: 'errada'), throwsA(isA<CredenciaisInvalidas>()));
    }
    await repo.entrar(email: email, senha: AuthRepositorioSimulado.senhaDeTeste);
    await expectLater(repo.entrar(email: email, senha: 'errada'), throwsA(isA<CredenciaisInvalidas>()));
  });
}
