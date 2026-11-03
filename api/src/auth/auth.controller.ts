import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto, RecuperarSenhaDto } from './dto/login.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  entrar(@Body() dados: LoginDto) {
    return this.auth.entrar(dados.email, dados.senha);
  }

  @Post('recuperar-senha')
  @HttpCode(HttpStatus.NO_CONTENT)
  // O DTO só valida o formato do e-mail; ainda não há envio (HU03).
  recuperarSenha(@Body() _dados: RecuperarSenhaDto) {
    return this.auth.solicitarRecuperacaoSenha();
  }
}
