import { DURACAO_BLOQUEIO_MS, MAXIMO_TENTATIVAS, TentativasLogin } from './tentativas-login.js';

const EMAIL = 'admin@clube.com.br';
const INICIO = 1_000_000;

function falhar(tentativas: TentativasLogin, vezes: number, agora = INICIO) {
  for (let i = 0; i < vezes; i++) tentativas.registrarFalha(EMAIL, agora);
}

describe('TentativasLogin', () => {
  it('não bloqueia antes de atingir o máximo de tentativas', () => {
    const tentativas = new TentativasLogin();
    falhar(tentativas, MAXIMO_TENTATIVAS - 1);
    expect(tentativas.minutosDeBloqueio(EMAIL, INICIO)).toBe(0);
  });

  it('bloqueia pelo tempo definido ao atingir o máximo de tentativas', () => {
    const tentativas = new TentativasLogin();
    falhar(tentativas, MAXIMO_TENTATIVAS);
    expect(tentativas.minutosDeBloqueio(EMAIL, INICIO)).toBe(DURACAO_BLOQUEIO_MS / 60_000);
  });

  it('informa os minutos restantes arredondando para cima', () => {
    const tentativas = new TentativasLogin();
    falhar(tentativas, MAXIMO_TENTATIVAS);
    const quaseNoFim = INICIO + DURACAO_BLOQUEIO_MS - 30_000;
    expect(tentativas.minutosDeBloqueio(EMAIL, quaseNoFim)).toBe(1);
  });

  it('libera o e-mail quando o bloqueio expira', () => {
    const tentativas = new TentativasLogin();
    falhar(tentativas, MAXIMO_TENTATIVAS);
    expect(tentativas.minutosDeBloqueio(EMAIL, INICIO + DURACAO_BLOQUEIO_MS)).toBe(0);
  });

  it('recomeça a contagem depois de um bloqueio expirado', () => {
    const tentativas = new TentativasLogin();
    falhar(tentativas, MAXIMO_TENTATIVAS);
    const depois = INICIO + DURACAO_BLOQUEIO_MS;
    tentativas.minutosDeBloqueio(EMAIL, depois);
    falhar(tentativas, MAXIMO_TENTATIVAS - 1, depois);
    expect(tentativas.minutosDeBloqueio(EMAIL, depois)).toBe(0);
  });

  it('zera a contagem após um login bem-sucedido', () => {
    const tentativas = new TentativasLogin();
    falhar(tentativas, MAXIMO_TENTATIVAS - 1);
    tentativas.limpar(EMAIL);
    falhar(tentativas, 1);
    expect(tentativas.minutosDeBloqueio(EMAIL, INICIO)).toBe(0);
  });

  it('conta as tentativas de cada e-mail separadamente', () => {
    const tentativas = new TentativasLogin();
    falhar(tentativas, MAXIMO_TENTATIVAS);
    expect(tentativas.minutosDeBloqueio('outro@clube.com.br', INICIO)).toBe(0);
  });
});
