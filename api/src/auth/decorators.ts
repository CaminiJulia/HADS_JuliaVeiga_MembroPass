import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';
import type { Request } from 'express';
import type { Papel, UsuarioAutenticado } from './papel.js';

export interface RequisicaoAutenticada extends Request {
  usuario?: UsuarioAutenticado;
}

export const PUBLICO = 'publico';
export const PAPEIS = 'papeis';
export const PERMITE_EM_HABILITACAO = 'permiteEmHabilitacao';

// Rota acessível sem login.
export const Publico = () => SetMetadata(PUBLICO, true);

// Papéis autorizados na rota. Rotas não públicas sem este decorator são negadas.
export const Papeis = (...papeis: Papel[]) => SetMetadata(PAPEIS, papeis);

// Libera a rota enquanto a organização aguarda a habilitação (RF03, HU01).
export const PermiteOrganizacaoEmHabilitacao = () => SetMetadata(PERMITE_EM_HABILITACAO, true);

export const UsuarioAtual = createParamDecorator(
  (_dados: unknown, contexto: ExecutionContext) =>
    contexto.switchToHttp().getRequest<RequisicaoAutenticada>().usuario,
);
