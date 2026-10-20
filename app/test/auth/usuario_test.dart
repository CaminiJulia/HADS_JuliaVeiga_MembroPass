import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/auth/usuario.dart';
import 'package:membropass/tema.dart';

void main() {
  test('lê o usuário devolvido pela API', () {
    final usuario = Usuario.deJson({
      'id': 'b0000000-0000-4000-8000-000000000001',
      'papel': 'administrador',
      'nome': 'Marina Oliveira',
      'email': 'admin@clubeatletico.com.br',
      'organizacao': {
        'id': 'a0000000-0000-4000-8000-000000000001',
        'nome': 'Clube Atlético Passo Fundo',
        'status': 'HABILITADA',
        'logoUrl': null,
        'corPrincipal': '#1E3A8A',
      },
    });

    expect(usuario.papel, Papel.administrador);
    expect(usuario.organizacao.habilitada, isTrue);
    expect(usuario.organizacao.corPrincipal, '#1E3A8A');
  });

  test('rejeita papel desconhecido', () {
    expect(() => Papel.deTexto('gerente'), throwsFormatException);
  });

  group('corDeHex', () {
    test('converte #RRGGBB em cor', () {
      expect(corDeHex('#1E3A8A'), const Color(0xFF1E3A8A));
    });

    test('ignora valores ausentes ou inválidos', () {
      expect(corDeHex(null), isNull);
      expect(corDeHex('azul'), isNull);
      expect(corDeHex('#12345'), isNull);
    });
  });
}
