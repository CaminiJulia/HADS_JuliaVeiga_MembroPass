import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { RegistrarCheckinDto } from './dto/registrar-checkin.dto';
import { OperadorService } from './operador.service';

// Área do operador no app: exclusivamente o check-in (RF02 e RF10).
@Controller('operador')
@Apenas('operador')
export class OperadorController {
  constructor(private readonly operador: OperadorService) {}

  @Get('locais')
  locais(@Usuario() usuario: UsuarioLogado) {
    return this.operador.locais(usuario.organizacaoId);
  }

  @Get('locais/:id/checkins')
  checkinsDeHoje(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.operador.checkinsDeHoje(usuario.organizacaoId, id);
  }

  @Post('checkins')
  registrar(
    @Usuario() usuario: UsuarioLogado,
    @Body() dados: RegistrarCheckinDto,
  ) {
    return this.operador.registrar(usuario.id, usuario.organizacaoId, dados);
  }
}
