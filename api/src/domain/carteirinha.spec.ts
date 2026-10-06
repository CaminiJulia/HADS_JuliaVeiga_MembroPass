import {
  calcularNovoVencimento,
  calcularSituacao,
  DIAS_ALERTA_VENCIMENTO,
  somarDias,
} from './carteirinha.js';

const data = (iso: string) => new Date(`${iso}T00:00:00Z`);
const HOJE = data('2026-10-12');

describe('calcularSituacao', () => {
  it('retorna ATIVA quando faltam mais dias que o alerta de vencimento', () => {
    const vencimento = somarDias(HOJE, DIAS_ALERTA_VENCIMENTO + 1);
    expect(calcularSituacao('ATIVA', vencimento, HOJE)).toBe('ATIVA');
  });

  it('retorna VENCENDO no limite do alerta de vencimento', () => {
    const vencimento = somarDias(HOJE, DIAS_ALERTA_VENCIMENTO);
    expect(calcularSituacao('ATIVA', vencimento, HOJE)).toBe('VENCENDO');
  });

  it('retorna VENCENDO no próprio dia do vencimento', () => {
    expect(calcularSituacao('ATIVA', HOJE, HOJE)).toBe('VENCENDO');
  });

  it('retorna VENCIDA a partir do dia seguinte ao vencimento', () => {
    expect(calcularSituacao('ATIVA', data('2026-10-11'), HOJE)).toBe('VENCIDA');
  });

  it('não bloqueia automaticamente: carteirinha vencida continua com status ATIVA no banco', () => {
    const situacao = calcularSituacao('ATIVA', data('2026-01-01'), HOJE);
    expect(situacao).toBe('VENCIDA');
    expect(situacao).not.toBe('BLOQUEADA');
  });

  it('mantém BLOQUEADA mesmo dentro do ciclo vigente', () => {
    expect(calcularSituacao('BLOQUEADA', data('2027-01-01'), HOJE)).toBe('BLOQUEADA');
  });

  it('mantém INVALIDADA mesmo dentro do ciclo vigente', () => {
    expect(calcularSituacao('INVALIDADA', data('2027-01-01'), HOJE)).toBe('INVALIDADA');
  });
});

describe('calcularNovoVencimento', () => {
  it.each([
    [30, '2026-11-11'],
    [90, '2027-01-10'],
    [365, '2027-10-12'],
  ])('soma %i dias à data da confirmação', (duracao, esperado) => {
    expect(calcularNovoVencimento(HOJE, duracao)).toEqual(data(esperado));
  });

  it.each([0, -30, 1.5])('rejeita duração inválida (%s)', (duracao) => {
    expect(() => calcularNovoVencimento(HOJE, duracao)).toThrow(RangeError);
  });
});
