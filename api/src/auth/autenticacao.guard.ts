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
import { BancoService } from '../banco/banco.service';
import type { Papel } from './auth.service';
import { TABELA_DA_CONTA } from './contas';

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
  sv: number; // versão da sessão
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
    private readonly banco: BancoService,
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

    // O token sozinho não basta: a conta precisa continuar ativa, numa
    // organização não suspensa, e sem troca de senha depois da emissão.
    // Assim desativar alguém ou redefinir a senha encerra a sessão na hora.
    const [ativa] = await this.banco.consultar(
      `SELECT 1 FROM ${TABELA_DA_CONTA[conteudo.papel]} c
       JOIN organizacao o ON o.id = c.organizacao_id AND o.status <> 'SUSPENSA'
       WHERE c.id = $1 AND c.status = 'ATIVO'
         AND c.versao_sessao = $2`,
      [conteudo.sub, conteudo.sv ?? 0],
    );
    if (!ativa) {
      throw new UnauthorizedException(
        'Sua sessão foi encerrada. Entre novamente.',
      );
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
