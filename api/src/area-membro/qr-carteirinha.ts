import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

// Conteúdo do QR Code da carteirinha (RF05). O check-in do operador (RF10)
// confere a assinatura e se a versão ainda é a atual: liberar ciclo,
// bloquear ou desativar aumenta a versão e invalida o QR Code antigo.
export interface ConteudoQr {
  c: string; // id da carteirinha
  v: number; // versão do QR
  o: string; // organização
}

// QR fixo: o mesmo código enquanto a versão da carteirinha não muda. Sem
// validade e sem data de emissão, a assinatura sai sempre igual.
@Injectable()
export class QrCarteirinha {
  // Assinador próprio, com segredo separado do login e sem a validade padrão
  // dos tokens de acesso: um QR nunca serve como login, nem o login como QR.
  private readonly jwt: JwtService;

  constructor(config: ConfigService) {
    this.jwt = new JwtService({
      secret: `${config.getOrThrow<string>('JWT_SECRET')}:qr-carteirinha`,
      signOptions: { noTimestamp: true },
    });
  }

  async gerar(conteudo: ConteudoQr) {
    const codigo = await this.jwt.signAsync({
      c: conteudo.c,
      v: conteudo.v,
      o: conteudo.o,
    });
    return { codigo };
  }

  // Devolve o conteúdo, ou null se a assinatura não confere.
  async ler(codigo: string): Promise<ConteudoQr | null> {
    try {
      return await this.jwt.verifyAsync<ConteudoQr>(codigo);
    } catch {
      return null;
    }
  }
}
