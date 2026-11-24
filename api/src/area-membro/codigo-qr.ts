import { createHmac, timingSafeEqual } from 'node:crypto';

// QR Code dinâmico da carteirinha (RF05), no estilo dos códigos de dois
// fatores: o app recebe uma chave da carteirinha e, com ela, gera sozinho
// (até sem internet) um código novo a cada PASSO_SEGUNDOS. Uma foto ou
// captura de tela do QR para de funcionar em cerca de um minuto.
//
// Conteúdo do QR:  MP2.<id da carteirinha>.<versão>.<passo>.<assinatura>
//   passo      = segundos desde 1970 / PASSO_SEGUNDOS (arredondado para baixo)
//   assinatura = HMAC-SHA256(chave, passo), 12 primeiros bytes, base64url
//   chave      = HMAC-SHA256(segredo do servidor, "id:versão")
//
// A versão sobe ao liberar ciclo, bloquear ou desativar: a chave muda e os
// códigos gerados com a chave antiga deixam de valer.

export const PASSO_SEGUNDOS = 30;

// Passos de tolerância para cada lado: cobre relógios levemente diferentes
// entre o celular do membro e o servidor, e o tempo de mirar a câmera.
const TOLERANCIA_PASSOS = 1;

const PREFIXO = 'MP2';

// Expirado ainda diz de quem é a carteirinha: a assinatura confere, só o
// momento é que passou (captura de tela ou foto).
export type LeituraQr =
  | { ok: true; carteirinhaId: string; versao: number }
  | { ok: false; motivo: 'expirado'; carteirinhaId: string; versao: number }
  | { ok: false; motivo: 'invalido' };

// Número curto da carteirinha, para conferência visual: os 8 primeiros
// caracteres do id, sem hífens.
export function numeroCarteirinha(carteirinhaId: string) {
  return carteirinhaId.replace(/-/g, '').slice(0, 8).toUpperCase();
}

export function passoAtual(agoraMs = Date.now()) {
  return Math.floor(agoraMs / 1000 / PASSO_SEGUNDOS);
}

// Assinatura de um passo com a chave. O app (Dart) faz a mesma conta.
export function assinarPasso(chave: Buffer, passo: number) {
  return createHmac('sha256', chave)
    .update(String(passo))
    .digest()
    .subarray(0, 12)
    .toString('base64url');
}

// A conta do QR, sem nada do Nest (para os testes rodarem direto).
export class CodigoQr {
  constructor(private readonly segredo: string) {}

  // Chave entregue ao app do membro junto com a carteirinha.
  chave(carteirinhaId: string, versao: number): Buffer {
    return createHmac('sha256', this.segredo)
      .update(`${carteirinhaId}:${versao}`)
      .digest();
  }

  // Confere o texto lido pelo operador.
  ler(codigo: string, agoraMs = Date.now()): LeituraQr {
    const partes = codigo.trim().split('.');
    if (partes.length !== 5 || partes[0] !== PREFIXO) {
      return { ok: false, motivo: 'invalido' };
    }
    const [, carteirinhaId, textoVersao, textoPasso, assinatura] = partes;
    const versao = Number(textoVersao);
    const passo = Number(textoPasso);
    if (!Number.isInteger(versao) || !Number.isInteger(passo)) {
      return { ok: false, motivo: 'invalido' };
    }

    const esperada = Buffer.from(
      assinarPasso(this.chave(carteirinhaId, versao), passo),
    );
    const recebida = Buffer.from(assinatura);
    // Comparação em tempo constante: não dá pistas da assinatura certa.
    if (
      esperada.length !== recebida.length ||
      !timingSafeEqual(esperada, recebida)
    ) {
      return { ok: false, motivo: 'invalido' };
    }
    // Assinatura válida, mas de outro momento: captura de tela ou foto.
    if (Math.abs(passoAtual(agoraMs) - passo) > TOLERANCIA_PASSOS) {
      return { ok: false, motivo: 'expirado', carteirinhaId, versao };
    }
    return { ok: true, carteirinhaId, versao };
  }
}
