import { Body, Controller, Get, Put } from '@nestjs/common';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { SalvarPerfilDto } from './dto/perfil.dto';
import { PapelComPerfil, PerfilService } from './perfil.service';

// Aba "Meu perfil" do administrador e do operador: foto e dados de contato.
// A troca de senha é em PUT /auth/senha (vale para todos os papéis). O papel do token escolhe o cadastro (cada papel tem o seu).
@Controller('perfil')
@Apenas('administrador', 'operador')
export class PerfilController {
  constructor(private readonly perfil: PerfilService) {}

  @Get()
  buscar(@Usuario() usuario: UsuarioLogado) {
    return this.perfil.buscar(papel(usuario), usuario.id);
  }

  @Put()
  salvar(@Usuario() usuario: UsuarioLogado, @Body() dados: SalvarPerfilDto) {
    return this.perfil.salvar(papel(usuario), usuario.id, dados);
  }
}

// O @Apenas acima garante que só chegam esses dois papéis.
const papel = (usuario: UsuarioLogado) => usuario.papel as PapelComPerfil;
