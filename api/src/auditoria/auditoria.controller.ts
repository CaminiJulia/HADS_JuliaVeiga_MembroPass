import { Controller, Get } from '@nestjs/common';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { BancoService } from '../banco/banco.service';
import { listarAuditoria } from './auditoria';

// RF16: histórico das ações sensíveis da organização (somente leitura).
@Controller('auditoria')
@Apenas('administrador')
export class AuditoriaController {
  constructor(private readonly banco: BancoService) {}

  @Get()
  listar(@Usuario() usuario: UsuarioLogado) {
    return listarAuditoria(this.banco.consultar, usuario.organizacaoId);
  }
}
