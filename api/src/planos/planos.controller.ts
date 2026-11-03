import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
} from '@nestjs/common';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { AlterarStatusPlanoDto, SalvarPlanoDto } from './dto/plano.dto';
import { PlanosService } from './planos.service';

@Controller('planos')
@Apenas('administrador')
export class PlanosController {
  constructor(private readonly planos: PlanosService) {}

  @Get()
  listar(@Usuario() usuario: UsuarioLogado) {
    return this.planos.listar(usuario.organizacaoId);
  }

  @Post()
  criar(@Usuario() usuario: UsuarioLogado, @Body() dados: SalvarPlanoDto) {
    return this.planos.criar(usuario.organizacaoId, dados);
  }

  @Put(':id')
  editar(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: SalvarPlanoDto,
  ) {
    return this.planos.editar(usuario.organizacaoId, id, dados, usuario);
  }

  @Patch(':id/status')
  alterarStatus(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: AlterarStatusPlanoDto,
  ) {
    return this.planos.alterarStatus(usuario.organizacaoId, id, dados.status);
  }
}
