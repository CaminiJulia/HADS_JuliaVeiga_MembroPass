import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/core/validacao/validadores.dart';

void main() {
  group('Validadores.email', () {
    test('rejeita vazio', () {
      expect(Validadores.email(''), 'Informe seu e-mail.');
      expect(Validadores.email('   '), 'Informe seu e-mail.');
      expect(Validadores.email(null), 'Informe seu e-mail.');
    });

    test('rejeita formato inválido', () {
      for (final invalido in ['ana', 'ana@', 'ana@org', '@org.com', 'ana @org.com']) {
        expect(Validadores.email(invalido), 'Informe um e-mail válido.', reason: invalido);
      }
    });

    test('aceita e-mail válido, ignorando espaços nas pontas', () {
      expect(Validadores.email('ana@org.com.br'), isNull);
      expect(Validadores.email('  ana@org.com  '), isNull);
    });
  });

  group('Validadores.senha', () {
    test('rejeita vazia', () {
      expect(Validadores.senha(''), 'Informe sua senha.');
      expect(Validadores.senha(null), 'Informe sua senha.');
    });

    test('aceita qualquer senha preenchida', () {
      expect(Validadores.senha('x'), isNull);
    });
  });
}
