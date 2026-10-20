import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

// As senhas são guardadas com bcrypt pela extensão pgcrypto (RNF07), o mesmo
// formato usado nos dados de teste. A comparação é feita pelo próprio banco.
@Injectable()
export class SenhasService {
  private hashFicticio?: Promise<string>;

  constructor(private readonly prisma: PrismaService) {}

  async verificar(senha: string, hash: string): Promise<boolean> {
    try {
      const [resultado] = await this.prisma.$queryRaw<{ valida: boolean }[]>`
        SELECT crypt(${senha}, ${hash}) = ${hash} AS valida`;
      return resultado?.valida === true;
    } catch {
      // Hash fora do formato bcrypt.
      return false;
    }
  }

  // Hash usado quando o e-mail não existe, para que a resposta demore o mesmo
  // tempo e não revele quais e-mails estão cadastrados.
  hashParaComparacaoFicticia(): Promise<string> {
    this.hashFicticio ??= this.prisma.$queryRaw<{ hash: string }[]>`
      SELECT crypt(gen_random_uuid()::text, gen_salt('bf', 10)) AS hash`.then(([r]) => r.hash);
    return this.hashFicticio;
  }
}
