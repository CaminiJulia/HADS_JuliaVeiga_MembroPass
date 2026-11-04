import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

// Conteúdo do QR Code da carteirinha (RF05). O check-in do operador (RF10)
// confere a assinatura, a validade e se a versão ainda é a atual: liberar
// ciclo, bloquear ou desativar aumenta a versão e invalida QR Codes antigos.
export interface ConteudoQr {
  c: string; // id da carteirinha
  v: number; // versão do QR
  o: string; // organização
}

// Validade curta: um print da tela deixa de servir em poucos minutos.
export const VALIDADE_QR_SEGUNDOS = 300;

@Injectable()
export class QrCarteirinha {
  // Segredo próprio, separado do login: um QR nunca serve como token de acesso.
  private readonly segredo: string;

  constructor(
    private readonly jwt: JwtService,
    config: ConfigService,
  ) {
    this.segredo = `${config.getOrThrow<string>('JWT_SECRET')}:qr-carteirinha`;
  }

  async gerar(conteudo: ConteudoQr) {
    const codigo = await this.jwt.signAsync(conteudo, {
      secret: this.segredo,
      expiresIn: VALIDADE_QR_SEGUNDOS,
    });
    const expiraEm = new Date(Date.now() + VALIDADE_QR_SEGUNDOS * 1000);
    return { codigo, expiraEm: expiraEm.toISOString() };
  }

  // Devolve o conteúdo, ou null se a assinatura ou a validade não conferem.
  async ler(codigo: string): Promise<ConteudoQr | null> {
    try {
      return await this.jwt.verifyAsync<ConteudoQr>(codigo, {
        secret: this.segredo,
      });
    } catch {
      return null;
    }
  }
}
