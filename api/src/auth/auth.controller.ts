import { Body, Controller, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { AuthService } from './auth.service.js';
import { Papeis, PermiteOrganizacaoEmHabilitacao, Publico, UsuarioAtual } from './decorators.js';
import { LoginDto } from './dto/login.dto.js';
import { TODOS_OS_PAPEIS, type UsuarioAutenticado } from './papel.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Publico()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto.email, dto.senha);
  }

  // Usado pelo app ao abrir, para restaurar a sessão salva e escolher a área do papel.
  @Get('eu')
  @Papeis(...TODOS_OS_PAPEIS)
  @PermiteOrganizacaoEmHabilitacao()
  eu(@UsuarioAtual() usuario: UsuarioAutenticado) {
    return this.auth.perfil(usuario.papel, usuario.id);
  }
}
