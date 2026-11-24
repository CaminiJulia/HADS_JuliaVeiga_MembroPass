import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  Put,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { Apenas, Usuario } from './autenticacao.guard';
import type { UsuarioLogado } from './autenticacao.guard';
import { LoginDto, RecuperarSenhaDto } from './dto/login.dto';
import { RedefinirSenhaDto, TrocarSenhaDto } from './dto/senha.dto';

// Limites por IP, além do bloqueio por e-mail do LimitadorTentativas: quem
// tenta muitos e-mails diferentes do mesmo lugar também é barrado.
const POR_MINUTO = (limit: number) => ({ default: { limit, ttl: 60_000 } });

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Throttle(POR_MINUTO(10))
  entrar(@Body() dados: LoginDto) {
    return this.auth.entrar(dados.email, dados.senha);
  }

  // Qualquer papel troca a própria senha (inclusive a provisória do primeiro
  // login). Devolve um token novo: as outras sessões são encerradas.
  @Put('senha')
  @Apenas('administrador', 'operador', 'membro')
  @Throttle(POR_MINUTO(10))
  trocarSenha(
    @Usuario() usuario: UsuarioLogado,
    @Body() dados: TrocarSenhaDto,
  ) {
    return this.auth.trocarSenha(usuario, dados.senhaAtual, dados.novaSenha);
  }

  @Post('recuperar-senha')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Throttle(POR_MINUTO(5))
  recuperarSenha(@Body() dados: RecuperarSenhaDto) {
    return this.auth.solicitarRecuperacaoSenha(dados.email);
  }

  @Post('redefinir-senha')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Throttle(POR_MINUTO(10))
  redefinirSenha(@Body() dados: RedefinirSenhaDto) {
    return this.auth.redefinirSenha(dados.email, dados.codigo, dados.novaSenha);
  }
}
