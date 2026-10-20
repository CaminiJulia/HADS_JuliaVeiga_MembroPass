import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { StatusOrganizacao } from '../../generated/prisma/client.js';
import type { PayloadAcesso } from '../auth.service.js';
import { ContasService } from '../contas.service.js';
import { PERMITE_EM_HABILITACAO, PUBLICO, RequisicaoAutenticada } from '../decorators.js';

// Valida o token e recarrega a conta a cada requisição, para que a desativação
// de um cadastro tenha efeito imediato. Também impede o uso do painel antes da
// habilitação da organização (RF03).
@Injectable()
export class AutenticacaoGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly jwt: JwtService,
    private readonly contas: ContasService,
  ) {}

  async canActivate(contexto: ExecutionContext): Promise<boolean> {
    const alvos = [contexto.getHandler(), contexto.getClass()];
    if (this.reflector.getAllAndOverride<boolean>(PUBLICO, alvos)) return true;

    const requisicao = contexto.switchToHttp().getRequest<RequisicaoAutenticada>();
    const [tipo, token] = requisicao.headers.authorization?.split(' ') ?? [];
    if (tipo !== 'Bearer' || !token) {
      throw new UnauthorizedException('Faça login para continuar.');
    }

    const sessaoInvalida = new UnauthorizedException('Sessão inválida ou expirada.');
    let payload: PayloadAcesso;
    try {
      payload = await this.jwt.verifyAsync<PayloadAcesso>(token);
    } catch {
      throw sessaoInvalida;
    }
    const conta = await this.contas.buscarPorId(payload.papel, payload.sub);
    if (!conta?.ativa) throw sessaoInvalida;

    if (
      conta.organizacao.status !== StatusOrganizacao.HABILITADA &&
      !this.reflector.getAllAndOverride<boolean>(PERMITE_EM_HABILITACAO, alvos)
    ) {
      throw new ForbiddenException('A organização ainda não foi habilitada pela equipe MembroPass.');
    }

    requisicao.usuario = { id: conta.id, papel: conta.papel, organizacaoId: conta.organizacaoId };
    return true;
  }
}
