import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/features/area_membro/domain/carteirinha_membro.dart';

void main() {
  // Mesma chave, mesmo instante: o código precisa ser idêntico ao que a API
  // calcula (valor de referência gerado com o Node, em api/src/area-membro/codigo-qr.ts).
  final chave = ChaveQr(carteirinhaId: 'abc', versao: 3, chave: Uint8List.fromList(List.generate(32, (i) => i)));
  final instante = DateTime.fromMillisecondsSinceEpoch(1795000000000);

  test('gera o mesmo código que a API', () {
    expect(chave.codigo(instante), 'MP2.abc.3.59833333.CM133M_z_5WluKuw');
  });

  test('o código muda no passo seguinte e se mantém dentro do passo', () {
    final inicio = DateTime.fromMillisecondsSinceEpoch(59833333 * 30 * 1000);
    expect(chave.codigo(inicio.add(const Duration(seconds: 29))), chave.codigo(inicio));
    expect(chave.codigo(inicio.add(const Duration(seconds: 30))), isNot(chave.codigo(inicio)));
    expect(chave.ateProximoCodigo(inicio.add(const Duration(seconds: 10))), const Duration(seconds: 20));
  });

  test('corrige o relógio do celular pela hora do servidor', () {
    final atrasado = ChaveQr.deJson({
      'carteirinhaId': 'abc',
      'versao': 3,
      'chave': 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=',
      'passoSegundos': 30,
      'agora': instante.millisecondsSinceEpoch,
    }, agoraLocal: instante.subtract(const Duration(minutes: 5)));
    // Celular 5 minutos atrasado: ainda assim gera o código do servidor.
    expect(atrasado.codigo(instante.subtract(const Duration(minutes: 5))), chave.codigo(instante));
  });
}
