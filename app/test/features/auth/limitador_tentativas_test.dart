import 'package:flutter_test/flutter_test.dart';
import 'package:membropass/features/auth/domain/limitador_tentativas.dart';

void main() {
  late DateTime agora;
  late LimitadorTentativas limitador;

  setUp(() {
    agora = DateTime(2026, 10, 28, 10);
    limitador = LimitadorTentativas(
      maximoTentativas: 3,
      tempoBloqueio: const Duration(minutes: 1),
      relogio: () => agora,
    );
  });

  test('não bloqueia antes de atingir o limite', () {
    limitador.registrarFalha('ana@org.com');
    limitador.registrarFalha('ana@org.com');
    expect(limitador.tempoRestante('ana@org.com'), isNull);
  });

  test('bloqueia ao atingir o limite de tentativas', () {
    for (var i = 0; i < 3; i++) {
      limitador.registrarFalha('ana@org.com');
    }
    expect(limitador.tempoRestante('ana@org.com'), const Duration(minutes: 1));
  });

  test('libera após o tempo de bloqueio e zera a contagem', () {
    for (var i = 0; i < 3; i++) {
      limitador.registrarFalha('ana@org.com');
    }
    agora = agora.add(const Duration(minutes: 1));
    expect(limitador.tempoRestante('ana@org.com'), isNull);

    limitador.registrarFalha('ana@org.com');
    expect(limitador.tempoRestante('ana@org.com'), isNull);
  });

  test('trata o e-mail sem diferenciar maiúsculas e espaços', () {
    limitador.registrarFalha('Ana@Org.com');
    limitador.registrarFalha(' ana@org.com ');
    limitador.registrarFalha('ANA@ORG.COM');
    expect(limitador.tempoRestante('ana@org.com'), isNotNull);
  });

  test('contagem é separada por e-mail', () {
    for (var i = 0; i < 3; i++) {
      limitador.registrarFalha('ana@org.com');
    }
    expect(limitador.tempoRestante('bia@org.com'), isNull);
  });

  test('limpar zera as falhas após um login bem-sucedido', () {
    limitador.registrarFalha('ana@org.com');
    limitador.registrarFalha('ana@org.com');
    limitador.limpar('ana@org.com');
    limitador.registrarFalha('ana@org.com');
    expect(limitador.tempoRestante('ana@org.com'), isNull);
  });
}
