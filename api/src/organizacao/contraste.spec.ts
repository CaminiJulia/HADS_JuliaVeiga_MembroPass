import { CONTRASTE_MINIMO, contrasteComBranco } from './contraste';

describe('contrasteComBranco', () => {
  it('preto tem contraste máximo e branco, mínimo', () => {
    expect(contrasteComBranco('#000000')).toBeCloseTo(21, 1);
    expect(contrasteComBranco('#FFFFFF')).toBeCloseTo(1, 5);
  });

  it('azul da marca passa; amarelo claro não', () => {
    expect(contrasteComBranco('#2B2FB8')).toBeGreaterThan(CONTRASTE_MINIMO);
    expect(contrasteComBranco('#FFD54F')).toBeLessThan(CONTRASTE_MINIMO);
  });

  it('valor de referência da WCAG: #767676 fica em 4,54:1', () => {
    expect(contrasteComBranco('#767676')).toBeCloseTo(4.54, 2);
  });
});
