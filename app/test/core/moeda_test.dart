import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/core/formatacao/moeda.dart';

void main() {
  test('formata em reais, com separador de milhar', () {
    expect(Moeda.formatar(0), 'R\$ 0,00');
    expect(Moeda.formatar(89.9), 'R\$ 89,90');
    expect(Moeda.formatar(1234.5), 'R\$ 1.234,50');
    expect(Moeda.formatar(1234567.891), 'R\$ 1.234.567,89');
  });

  test('lê valores digitados no formato brasileiro', () {
    expect(Moeda.ler('89,90'), 89.9);
    expect(Moeda.ler('89,9'), 89.9);
    expect(Moeda.ler('89'), 89);
    expect(Moeda.ler('1.234,50'), 1234.5);
    expect(Moeda.ler('R\$ 10,00'), 10);
  });

  test('rejeita valores inválidos', () {
    for (final invalido in ['', 'abc', '10,999', '-5', '1,2,3']) {
      expect(Moeda.ler(invalido), isNull, reason: invalido);
    }
  });

  test('paraCampo devolve o valor pronto para edição', () {
    expect(Moeda.paraCampo(89.9), '89,90');
  });
}
