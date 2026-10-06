// Regras de domínio da carteirinha digital (RF05, RF07, RNF06).
// Espelham a função fn_situacao_carteirinha do banco de dados.

export const DIAS_ALERTA_VENCIMENTO = 7;

export type StatusCarteirinha = 'ATIVA' | 'BLOQUEADA' | 'INVALIDADA';
export type SituacaoCarteirinha = 'ATIVA' | 'VENCENDO' | 'VENCIDA' | 'BLOQUEADA' | 'INVALIDADA';

const MS_POR_DIA = 24 * 60 * 60 * 1000;

// Datas de calendário são tratadas como meia-noite UTC, como o Prisma devolve colunas DATE.
export function hoje(fusoHorario = 'America/Sao_Paulo'): Date {
  const iso = new Date().toLocaleDateString('en-CA', { timeZone: fusoHorario });
  return new Date(`${iso}T00:00:00Z`);
}

export function somarDias(data: Date, dias: number): Date {
  return new Date(data.getTime() + dias * MS_POR_DIA);
}

export function diasEntre(de: Date, ate: Date): number {
  return Math.round((ate.getTime() - de.getTime()) / MS_POR_DIA);
}

// "Vencida" e "vencendo" são apenas sinalizações: o sistema nunca bloqueia
// automaticamente. Só o administrador bloqueia (RF07).
export function calcularSituacao(
  status: StatusCarteirinha,
  dataVencimento: Date,
  referencia: Date = hoje(),
): SituacaoCarteirinha {
  if (status !== 'ATIVA') return status;

  const diasRestantes = diasEntre(referencia, dataVencimento);
  if (diasRestantes < 0) return 'VENCIDA';
  if (diasRestantes <= DIAS_ALERTA_VENCIMENTO) return 'VENCENDO';
  return 'ATIVA';
}

// RF07: novo vencimento = data da confirmação do pagamento + duração do plano.
export function calcularNovoVencimento(dataConfirmacao: Date, duracaoDias: number): Date {
  if (!Number.isInteger(duracaoDias) || duracaoDias <= 0) {
    throw new RangeError('A duração do plano deve ser um número inteiro de dias maior que zero.');
  }
  return somarDias(dataConfirmacao, duracaoDias);
}
