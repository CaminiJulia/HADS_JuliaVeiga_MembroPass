import type { Consulta } from '../banco/banco.service';
import type { UsuarioLogado } from '../auth/autenticacao.guard';

export type AcaoAuditoria =
  | 'LIBERACAO_CICLO'
  | 'BLOQUEIO_MANUAL'
  | 'DESBLOQUEIO'
  | 'DESATIVACAO_MEMBRO'
  | 'REATIVACAO_MEMBRO'
  | 'EDICAO_PLANO';

export interface RegistroAuditoria {
  id: string;
  acao: AcaoAuditoria;
  entidade: string;
  entidadeId: string;
  descricao: string;
  justificativa: string | null;
  administradorNome: string;
  dataHora: string;
}

interface LinhaAuditoria {
  id: string;
  acao: AcaoAuditoria;
  entidade: string;
  entidade_id: string;
  descricao: string;
  justificativa: string | null;
  administrador_nome: string;
  data_hora: Date;
}

// RF16: grava uma ação sensível. Use dentro da mesma transação da ação, para
// que a ação e o registro sejam gravados juntos (ou nenhum dos dois).
export async function registrarAuditoria(
  consultar: Consulta,
  usuario: UsuarioLogado,
  dados: {
    acao: AcaoAuditoria;
    entidade: string;
    entidadeId: string;
    descricao: string;
    justificativa?: string | null;
  },
) {
  await consultar(
    `INSERT INTO auditoria (organizacao_id, administrador_id, acao, entidade, entidade_id,
                            descricao, justificativa)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [
      usuario.organizacaoId,
      usuario.id,
      dados.acao,
      dados.entidade,
      dados.entidadeId,
      dados.descricao,
      dados.justificativa ?? null,
    ],
  );
}

// Registros da organização, do mais recente para o mais antigo.
// Com [entidadeId], só os daquele membro ou plano.
export async function listarAuditoria(
  consultar: Consulta,
  organizacaoId: string,
  entidadeId?: string,
): Promise<RegistroAuditoria[]> {
  const linhas = await consultar<LinhaAuditoria>(
    `SELECT a.id, a.acao, a.entidade, a.entidade_id, a.descricao, a.justificativa,
            ad.nome AS administrador_nome, a.data_hora
     FROM auditoria a
     JOIN administrador ad ON ad.id = a.administrador_id
     WHERE a.organizacao_id = $1 ${entidadeId ? 'AND a.entidade_id = $2' : ''}
     ORDER BY a.data_hora DESC
     LIMIT 200`,
    entidadeId ? [organizacaoId, entidadeId] : [organizacaoId],
  );
  return linhas.map((l) => ({
    id: l.id,
    acao: l.acao,
    entidade: l.entidade,
    entidadeId: l.entidade_id,
    descricao: l.descricao,
    justificativa: l.justificativa,
    administradorNome: l.administrador_nome,
    dataHora: l.data_hora.toISOString(),
  }));
}
