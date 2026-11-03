import {
  applyDecorators,
  CanActivate,
  createParamDecorator,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  SetMetadata,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import type { Request } from 'express';
import type { Papel } from './auth.service';

// Dados do token de quem fez a requisição (RF02).
export interface UsuarioLogado {
  id: string;
  papel: Papel;
  organizacaoId: string;
}

interface ConteudoToken {
  sub: string;
  papel: Papel;
  organizacaoId: string;
}

type RequisicaoComUsuario = Request & { usuario?: UsuarioLogado };

const CHAVE_PAPEIS = 'papeis';

// Exige token válido e um dos [papeis] informados.
// Ex.: `@Apenas('administrador')` no controller ou na rota.
export const Apenas = (...papeis: Papel[]) =>
  applyDecorators(
    SetMetadata(CHAVE_PAPEIS, papeis),
    UseGuards(AutenticacaoGuard),
  );

// Injeta na rota o usuário do token: `@Usuario() usuario: UsuarioLogado`.
export const Usuario = createParamDecorator(
  (_dados: unknown, contexto: ExecutionContext) =>
    contexto.switchToHttp().getRequest<RequisicaoComUsuario>().usuario,
);

@Injectable()
export class AutenticacaoGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(contexto: ExecutionContext) {
    const requisicao = contexto
      .switchToHttp()
      .getRequest<RequisicaoComUsuario>();
    const [tipo, token] = requisicao.headers.authorization?.split(' ') ?? [];
    if (tipo !== 'Bearer' || !token) {
      throw new UnauthorizedException('Faça login para continuar.');
    }

    let conteudo: ConteudoToken;
    try {
      conteudo = await this.jwt.verifyAsync<ConteudoToken>(token);
    } catch {
      throw new UnauthorizedException('Sua sessão expirou. Entre novamente.');
    }

    const papeis = this.reflector.getAllAndOverride<Papel[] | undefined>(
      CHAVE_PAPEIS,
      [contexto.getHandler(), contexto.getClass()],
    );
    if (papeis && !papeis.includes(conteudo.papel)) {
      throw new ForbiddenException('Você não tem acesso a esta área.');
    }

    requisicao.usuario = {
      id: conteudo.sub,
      papel: conteudo.papel,
      organizacaoId: conteudo.organizacaoId,
    };
    return true;
  }
}
