import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Put,
} from '@nestjs/common';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { SalvarPerfilDto, TrocarSenhaDto } from './dto/perfil.dto';
import { PerfilService } from './perfil.service';

// Aba "Meu perfil" do administrador: foto, dados de contato e senha.
@Controller('perfil')
@Apenas('administrador')
export class PerfilController {
  constructor(private readonly perfil: PerfilService) {}

  @Get()
  buscar(@Usuario() usuario: UsuarioLogado) {
    return this.perfil.buscar(usuario.id);
  }

  @Put()
  salvar(@Usuario() usuario: UsuarioLogado, @Body() dados: SalvarPerfilDto) {
    return this.perfil.salvar(usuario.id, dados);
  }

  @Put('senha')
  @HttpCode(HttpStatus.NO_CONTENT)
  trocarSenha(
    @Usuario() usuario: UsuarioLogado,
    @Body() dados: TrocarSenhaDto,
  ) {
    return this.perfil.trocarSenha(usuario.id, dados);
  }
}
