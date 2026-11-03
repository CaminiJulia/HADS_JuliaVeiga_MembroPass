import { LimitadorTentativas } from './limitador-tentativas';

describe('LimitadorTentativas', () => {
  let agora: number;
  let limitador: LimitadorTentativas;

  beforeEach(() => {
    agora = 0;
    limitador = new LimitadorTentativas(5, 60_000, () => agora);
  });

  it('não bloqueia antes da quinta falha', () => {
    for (let i = 0; i < 4; i++) limitador.registrarFalha('ana@org.com');
    expect(limitador.tempoRestante('ana@org.com')).toBeNull();
  });

  it('bloqueia na quinta falha, sem diferenciar maiúsculas', () => {
    for (let i = 0; i < 5; i++) limitador.registrarFalha('Ana@Org.com ');
    expect(limitador.tempoRestante('ana@org.com')).toBe(60_000);
  });

  it('libera depois do tempo de bloqueio e zera a contagem', () => {
    for (let i = 0; i < 5; i++) limitador.registrarFalha('ana@org.com');
    agora = 60_000;
    expect(limitador.tempoRestante('ana@org.com')).toBeNull();

    limitador.registrarFalha('ana@org.com');
    expect(limitador.tempoRestante('ana@org.com')).toBeNull();
  });

  it('limpar zera as falhas do e-mail', () => {
    for (let i = 0; i < 4; i++) limitador.registrarFalha('ana@org.com');
    limitador.limpar('ana@org.com');
    limitador.registrarFalha('ana@org.com');
    expect(limitador.tempoRestante('ana@org.com')).toBeNull();
  });
});
