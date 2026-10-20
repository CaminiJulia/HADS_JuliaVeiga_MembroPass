import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PAPEIS, PUBLICO, RequisicaoAutenticada } from '../decorators.js';
import type { Papel } from '../papel.js';

// Controle de acesso por papel (RF02, RNF09), pelo princípio do menor privilégio:
// nega por padrão, então toda rota não pública precisa declarar @Papeis().
@Injectable()
export class AutorizacaoGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(contexto: ExecutionContext): boolean {
    const alvos = [contexto.getHandler(), contexto.getClass()];
    if (this.reflector.getAllAndOverride<boolean>(PUBLICO, alvos)) return true;

    const papeis = this.reflector.getAllAndOverride<Papel[] | undefined>(PAPEIS, alvos) ?? [];
    const { usuario } = contexto.switchToHttp().getRequest<RequisicaoAutenticada>();
    if (!usuario || !papeis.includes(usuario.papel)) {
      throw new ForbiddenException('Seu perfil não tem permissão para esta ação.');
    }
    return true;
  }
}
