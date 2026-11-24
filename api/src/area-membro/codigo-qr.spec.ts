import {
  assinarPasso,
  PASSO_SEGUNDOS,
  passoAtual,
  CodigoQr,
} from './codigo-qr';

const ID = '6595e639-1111-4222-8333-444455556666';
const AGORA = Date.UTC(2026, 10, 24, 14, 0, 0);
const PASSO_MS = PASSO_SEGUNDOS * 1000;

const qr = new CodigoQr('segredo-de-teste-com-mais-de-32-caracteres');

// O que o app do membro monta, com a chave que recebeu.
function codigoDoApp(versao: number, agoraMs: number) {
  const passo = passoAtual(agoraMs);
  return `MP2.${ID}.${versao}.${passo}.${assinarPasso(qr.chave(ID, versao), passo)}`;
}

describe('CodigoQr', () => {
  it('aceita o código do passo atual', () => {
    expect(qr.ler(codigoDoApp(1, AGORA), AGORA)).toEqual({
      ok: true,
      carteirinhaId: ID,
      versao: 1,
    });
  });

  it('tolera um passo de diferença de relógio, para os dois lados', () => {
    expect(qr.ler(codigoDoApp(1, AGORA - PASSO_MS), AGORA).ok).toBe(true);
    expect(qr.ler(codigoDoApp(1, AGORA + PASSO_MS), AGORA).ok).toBe(true);
  });

  it('recusa como expirado o código de uma captura de tela antiga', () => {
    expect(qr.ler(codigoDoApp(1, AGORA - 3 * PASSO_MS), AGORA)).toEqual({
      ok: false,
      motivo: 'expirado',
      carteirinhaId: ID,
      versao: 1,
    });
  });

  it('recusa assinatura adulterada ou de outra versão', () => {
    const codigo = codigoDoApp(1, AGORA);
    const adulterado = codigo.slice(0, -1) + (codigo.endsWith('A') ? 'B' : 'A');
    expect(qr.ler(adulterado, AGORA)).toEqual({
      ok: false,
      motivo: 'invalido',
    });
    // Trocar só o número da versão no texto não basta: a chave é outra.
    expect(qr.ler(codigo.replace(`.${1}.`, '.2.'), AGORA).ok).toBe(false);
  });

  it('recusa textos que não são do MembroPass', () => {
    for (const texto of [
      '',
      'https://exemplo.com',
      'MP2.a.b.c',
      'abc.def.ghi',
    ]) {
      expect(qr.ler(texto, AGORA)).toEqual({ ok: false, motivo: 'invalido' });
    }
  });
});
