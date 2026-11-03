import { Controller, Get } from '@nestjs/common';
import { BancoService } from './banco/banco.service';

// Confere se a API está no ar e se consegue falar com o banco.
@Controller('saude')
export class SaudeController {
  constructor(private readonly banco: BancoService) {}

  @Get()
  async verificar() {
    await this.banco.consultar('SELECT 1');
    return { status: 'ok', banco: 'conectado' };
  }
}
