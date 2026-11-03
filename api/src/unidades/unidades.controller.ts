import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
} from '@nestjs/common';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { SalvarUnidadeEventoDto } from './dto/unidade-evento.dto';
import { UnidadesService } from './unidades.service';

@Controller('unidades-eventos')
@Apenas('administrador')
export class UnidadesController {
  constructor(private readonly unidades: UnidadesService) {}

  @Get()
  listar(@Usuario() usuario: UsuarioLogado) {
    return this.unidades.listar(usuario.organizacaoId);
  }

  @Post()
  criar(
    @Usuario() usuario: UsuarioLogado,
    @Body() dados: SalvarUnidadeEventoDto,
  ) {
    return this.unidades.criar(usuario.organizacaoId, dados);
  }

  @Put(':id')
  editar(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: SalvarUnidadeEventoDto,
  ) {
    return this.unidades.editar(usuario.organizacaoId, id, dados);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  excluir(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.unidades.excluir(usuario.organizacaoId, id);
  }
}
