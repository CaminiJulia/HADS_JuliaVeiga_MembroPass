import { avaliarCheckin, SituacaoLida } from './regras-checkin';

const HOJE = '2026-11-17';

const emDia: SituacaoLida = {
  membroAtivo: true,
  status: 'ATIVA',
  versaoAtual: 2,
  versaoLida: 2,
  qrExpirado: false,
  planoAceito: true,
  dataVencimento: '2026-12-01',
};

describe('avaliarCheckin', () => {
  it('aprova a carteirinha em dia', () => {
    expect(avaliarCheckin(emDia, HOJE)).toEqual({
      motivo: null,
      vencida: false,
    });
  });

  it('aprova a vencida, mas ativa, marcando o alerta', () => {
    expect(
      avaliarCheckin({ ...emDia, dataVencimento: '2026-11-16' }, HOJE),
    ).toEqual({ motivo: null, vencida: true });
  });

  it('vence no fim do dia: no próprio vencimento ainda não está vencida', () => {
    expect(
      avaliarCheckin({ ...emDia, dataVencimento: HOJE }, HOJE).vencida,
    ).toBe(false);
  });

  it('recusa membro desativado', () => {
    expect(avaliarCheckin({ ...emDia, membroAtivo: false }, HOJE).motivo).toBe(
      'MEMBRO_INATIVO',
    );
  });

  it('bloqueada mostra o bloqueio, mesmo com o QR de outra versão', () => {
    expect(
      avaliarCheckin({ ...emDia, status: 'BLOQUEADA', versaoLida: 1 }, HOJE)
        .motivo,
    ).toBe('CARTEIRINHA_BLOQUEADA');
  });

  it('recusa carteirinha invalidada', () => {
    expect(
      avaliarCheckin({ ...emDia, status: 'INVALIDADA' }, HOJE).motivo,
    ).toBe('CARTEIRINHA_INVALIDADA');
  });

  it('recusa QR de uma versão antiga', () => {
    expect(avaliarCheckin({ ...emDia, versaoLida: 1 }, HOJE).motivo).toBe(
      'QR_DESATUALIZADO',
    );
  });

  it('recusa QR expirado (captura de tela antiga)', () => {
    expect(avaliarCheckin({ ...emDia, qrExpirado: true }, HOJE).motivo).toBe(
      'QR_EXPIRADO',
    );
  });

  it('recusa plano que o local não aceita', () => {
    expect(avaliarCheckin({ ...emDia, planoAceito: false }, HOJE).motivo).toBe(
      'PLANO_NAO_ACEITO',
    );
  });
});
