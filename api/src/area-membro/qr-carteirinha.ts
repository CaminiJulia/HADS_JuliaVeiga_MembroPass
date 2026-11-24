import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CodigoQr } from './codigo-qr';

export {
  assinarPasso,
  numeroCarteirinha,
  PASSO_SEGUNDOS,
  passoAtual,
} from './codigo-qr';
export type { LeituraQr } from './codigo-qr';

// O CodigoQr com o segredo do .env. Segredo próprio, derivado do de login
// mas diferente dele: um QR nunca serve como token, nem o token como QR.
@Injectable()
export class QrCarteirinha extends CodigoQr {
  constructor(config: ConfigService) {
    super(`${config.getOrThrow<string>('JWT_SECRET')}:qr-carteirinha`);
  }
}
