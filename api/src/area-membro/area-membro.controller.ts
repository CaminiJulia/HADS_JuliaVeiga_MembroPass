import { Controller, Get } from '@nestjs/common';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { AreaMembroService } from './area-membro.service';

// Área do membro no app: carteirinha com QR Code, benefícios e locais.
@Controller('membro')
@Apenas('membro')
export class AreaMembroController {
  constructor(private readonly area: AreaMembroService) {}

  @Get('carteirinha')
  carteirinha(@Usuario() usuario: UsuarioLogado) {
    return this.area.carteirinha(usuario.id, usuario.organizacaoId);
  }

  @Get('beneficios')
  beneficios(@Usuario() usuario: UsuarioLogado) {
    return this.area.beneficios(usuario.id, usuario.organizacaoId);
  }

  @Get('locais')
  locais(@Usuario() usuario: UsuarioLogado) {
    return this.area.locais(usuario.id, usuario.organizacaoId);
  }
}
