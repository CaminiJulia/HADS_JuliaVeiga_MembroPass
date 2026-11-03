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
import { BeneficiosService } from './beneficios.service';
import { SalvarBeneficioDto } from './dto/beneficio.dto';

@Controller('beneficios')
@Apenas('administrador')
export class BeneficiosController {
  constructor(private readonly beneficios: BeneficiosService) {}

  @Get()
  listar(@Usuario() usuario: UsuarioLogado) {
    return this.beneficios.listar(usuario.organizacaoId);
  }

  @Post()
  criar(@Usuario() usuario: UsuarioLogado, @Body() dados: SalvarBeneficioDto) {
    return this.beneficios.criar(usuario.organizacaoId, dados);
  }

  @Put(':id')
  editar(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dados: SalvarBeneficioDto,
  ) {
    return this.beneficios.editar(usuario.organizacaoId, id, dados);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  excluir(
    @Usuario() usuario: UsuarioLogado,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.beneficios.excluir(usuario.organizacaoId, id);
  }
}
