import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

// Verifica se a API está no ar e conectada ao banco de dados.
@Controller('saude')
export class SaudeController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async verificar() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      throw new ServiceUnavailableException({ status: 'erro', banco: 'indisponível' });
    }
    return { status: 'ok', banco: 'conectado' };
  }
}
