// RF10: regras do check-in, separadas do SQL para serem testadas sozinhas.

export type MotivoRecusa =
  | 'QR_INVALIDO'
  | 'QR_DESATUALIZADO'
  | 'MEMBRO_INATIVO'
  | 'CARTEIRINHA_BLOQUEADA'
  | 'CARTEIRINHA_INVALIDADA'
  | 'PLANO_NAO_ACEITO'
  | 'NUMERO_INVALIDO'
  | 'QR_EXPIRADO';

// O texto que o operador lê na tela, para cada recusa.
export const MENSAGEM_RECUSA: Record<MotivoRecusa, string> = {
  QR_INVALIDO: 'QR Code não reconhecido como carteirinha desta organização.',
  QR_DESATUALIZADO:
    'QR Code desatualizado. Peça ao membro para abrir a carteirinha de novo no app.',
  MEMBRO_INATIVO: 'Membro desativado pela administração.',
  CARTEIRINHA_BLOQUEADA: 'Carteirinha bloqueada pela administração.',
  CARTEIRINHA_INVALIDADA: 'Carteirinha inativa.',
  PLANO_NAO_ACEITO: 'O plano do membro não dá acesso a este local.',
  QR_EXPIRADO:
    'QR Code expirado (o código muda a cada 30 segundos). Peça ao membro para mostrar a carteirinha aberta no app, não uma foto.',
  NUMERO_INVALIDO:
    'Nenhuma carteirinha desta organização com este número. Confira o que foi digitado.',
};

// O que a regra precisa saber da carteirinha lida.
export interface SituacaoLida {
  membroAtivo: boolean;
  status: 'ATIVA' | 'BLOQUEADA' | 'INVALIDADA';
  versaoAtual: number;
  versaoLida: number;
  // Assinatura válida, mas de outro momento: captura de tela ou foto.
  qrExpirado: boolean;
  planoAceito: boolean;
  dataVencimento: string; // AAAA-MM-DD
}

export interface Avaliacao {
  motivo: MotivoRecusa | null;
  // Vencida, mas ativa: entra com alerta. O sistema nunca bloqueia sozinho;
  // quem decide bloquear um membro vencido é o administrador.
  vencida: boolean;
}

// A ordem importa: bloquear também troca a versão do QR, e o operador deve
// ver o motivo real ("bloqueada"), não "QR desatualizado".
export function avaliarCheckin(s: SituacaoLida, hoje: string): Avaliacao {
  const vencida = s.dataVencimento < hoje;
  let motivo: MotivoRecusa | null = null;
  if (!s.membroAtivo) motivo = 'MEMBRO_INATIVO';
  else if (s.status === 'BLOQUEADA') motivo = 'CARTEIRINHA_BLOQUEADA';
  else if (s.status === 'INVALIDADA') motivo = 'CARTEIRINHA_INVALIDADA';
  else if (s.versaoLida !== s.versaoAtual) motivo = 'QR_DESATUALIZADO';
  else if (s.qrExpirado) motivo = 'QR_EXPIRADO';
  else if (!s.planoAceito) motivo = 'PLANO_NAO_ACEITO';
  return { motivo, vencida };
}
