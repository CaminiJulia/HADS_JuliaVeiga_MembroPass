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
} from '@nestjs/common';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import {
  AlterarStatusOperadorDto,
  SalvarOperadorDto,
} from './dto/operador.dto';
import { OperadoresService } from './operadores.service';

// Cadastro dos operadores, feito pelo administrador.
@Controller('operadores')
@Apenas('administrador')
export class OperadoresController {
  constructor(private readonly operadores: OperadoresService) {}

  @Get()
  listar(@Usuario() usuario: UsuarioLogado) {
    return this.operadores.listar(usuario.organizacaoId);
  }

  @Post()
  criar(@Usuario() usuario: UsuarioLogado, @Body() dados: SalvarOperadorDto) {
    return this.operadores.criar(usuario, dados);
  }

  @Put(':id')
  editar(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: SalvarOperadorDto,
  ) {
    return this.operadores.editar(usuario, id, dados);
  }

  @Patch(':id/status')
  alterarStatus(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: AlterarStatusOperadorDto,
  ) {
    return this.operadores.alterarStatus(usuario, id, dados.status);
  }

  @Post(':id/nova-senha')
  @HttpCode(HttpStatus.OK)
  novaSenha(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.operadores.novaSenha(usuario, id);
  }
}
