import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { Datas } from '../comum/datas';
import {
  AlterarStatusMembroDto,
  BloquearDto,
  BuscarMembrosDto,
  DesbloquearDto,
  LiberarCicloDto,
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
    return this.membros.alterarStatus(
      usuario,
      id,
      dados.status,
      dados.justificativa,
    );
  }

  @Post(':id/liberar-ciclo')
  @HttpCode(HttpStatus.OK)
  liberarCiclo(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: LiberarCicloDto,
  ) {
    return this.membros.liberarCiclo(
      usuario,
      id,
      dados.dataPagamento ?? Datas.hoje(),
    );
  }

  @Post(':id/bloquear')
  @HttpCode(HttpStatus.OK)
  bloquear(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: BloquearDto,
  ) {
    return this.membros.bloquear(usuario, id, dados.justificativa);
  }

  @Post(':id/desbloquear')
  @HttpCode(HttpStatus.OK)
  desbloquear(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: DesbloquearDto,
  ) {
    return this.membros.desbloquear(usuario, id, dados.justificativa);
  }

  @Get(':id/historico')
  historico(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.membros.historico(usuario.organizacaoId, id);
  }
}
