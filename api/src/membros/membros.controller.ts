import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import {
  AlterarStatusMembroDto,
  BuscarMembrosDto,
  SalvarMembroDto,
} from './dto/membro.dto';
import { MembrosService } from './membros.service';

@Controller('membros')
@Apenas('administrador')
export class MembrosController {
  constructor(private readonly membros: MembrosService) {}

  @Get()
  listar(@Usuario() usuario: UsuarioLogado, @Query() filtro: BuscarMembrosDto) {
    return this.membros.listar(usuario.organizacaoId, filtro.busca);
  }

  @Get(':id')
  buscar(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.membros.buscar(usuario.organizacaoId, id);
  }

  @Post()
  criar(@Usuario() usuario: UsuarioLogado, @Body() dados: SalvarMembroDto) {
    return this.membros.criar(usuario.organizacaoId, dados);
  }

  @Put(':id')
  editar(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: SalvarMembroDto,
  ) {
    return this.membros.editar(usuario.organizacaoId, id, dados);
  }

  @Patch(':id/status')
  alterarStatus(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: AlterarStatusMembroDto,
  ) {
    return this.membros.alterarStatus(usuario.organizacaoId, id, dados.status);
  }
}
