import { BadRequestException } from '@nestjs/common';
import type { Consulta } from '../banco/banco.service';

// Tabelas N:M com planos. Os nomes são fixos no código (nunca vêm da
// requisição), por isso podem entrar no SQL.
const VINCULOS = {
  beneficio: { tabela: 'plano_beneficio', coluna: 'beneficio_id' },
  unidadeEvento: {
    tabela: 'unidade_evento_plano',
    coluna: 'unidade_evento_id',
  },
} as const;

// Substitui os planos vinculados a [id]. Só aceita planos da mesma
// organização: um id de fora (ou inexistente) cancela a operação.
export async function vincularPlanos(
  consultar: Consulta,
  vinculo: keyof typeof VINCULOS,
  organizacaoId: string,
  id: string,
  planoIds: string[],
) {
  const { tabela, coluna } = VINCULOS[vinculo];
  await consultar(`DELETE FROM ${tabela} WHERE ${coluna} = $1`, [id]);

  const unicos = [...new Set(planoIds)];
  if (unicos.length === 0) return;
  const inseridos = await consultar(
    `INSERT INTO ${tabela} (plano_id, ${coluna})
     SELECT id, $2 FROM plano_associacao
     WHERE organizacao_id = $1 AND id = ANY($3::uuid[])
     RETURNING plano_id`,
    [organizacaoId, id, unicos],
  );
  if (inseridos.length !== unicos.length) {
    throw new BadRequestException('Algum plano escolhido não existe.');
  }
}
