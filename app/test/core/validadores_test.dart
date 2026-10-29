import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/core/validadores.dart';

void main() {
  group('Validadores.email', () {
    test('aceita e-mail válido, ignorando espaços nas pontas', () {
      expect(Validadores.email('membro@clube.com.br'), isNull);
      expect(Validadores.email('  membro@clube.com  '), isNull);
    });

    test('pede o e-mail quando está vazio', () {
      expect(Validadores.email(''), 'Informe seu e-mail.');
      expect(Validadores.email('   '), 'Informe seu e-mail.');
      expect(Validadores.email(null), 'Informe seu e-mail.');
    });

    test('recusa formatos inválidos', () {
      for (final valor in ['membro', 'membro@', '@clube.com', 'membro@clube', 'mem bro@clube.com']) {
        expect(Validadores.email(valor), 'E-mail inválido.', reason: valor);
      }
    });
  });

  group('Validadores.obrigatorio', () {
    test('usa o nome do campo na mensagem', () {
      expect(Validadores.obrigatorio('', campo: 'sua senha'), 'Informe sua senha.');
      expect(Validadores.obrigatorio(null, campo: 'sua senha'), 'Informe sua senha.');
    });

    test('não apara espaços, porque espaço pode fazer parte da senha', () {
      expect(Validadores.obrigatorio(' '), isNull);
    });
  });
}
