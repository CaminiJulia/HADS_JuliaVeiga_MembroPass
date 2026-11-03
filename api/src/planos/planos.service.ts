import { Injectable, NotFoundException } from '@nestjs/common';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { registrarAuditoria } from '../auditoria/auditoria';
import { BancoService } from '../banco/banco.service';
import { comUnico } from '../banco/erros';
import { SalvarPlanoDto } from './dto/plano.dto';

export interface Plano {
  id: string;
  nome: string;
  valorReferencia: number;
  duracaoDias: number;
  cor: string | null;
  status: 'ATIVO' | 'INATIVO';
}

interface LinhaPlano {
  id: string;
  nome: string;
  valor_referencia: string;
  duracao_dias: number;
  cor: string | null;
  status: 'ATIVO' | 'INATIVO';
}

const COLUNAS = 'id, nome, valor_referencia, duracao_dias, cor, status';
const NOME_REPETIDO = 'Já existe um plano com esse nome.';

// RF04. Toda consulta filtra pela organização do token (multi-tenant):
// um administrador nunca enxerga nem altera planos de outra organização.
@Injectable()
export class PlanosService {
  constructor(private readonly banco: BancoService) {}

  async listar(organizacaoId: string): Promise<Plano[]> {
    const linhas = await this.banco.consultar<LinhaPlano>(
      `SELECT ${COLUNAS} FROM plano_associacao
       WHERE organizacao_id = $1
       ORDER BY status, duracao_dias, nome`,
      [organizacaoId],
    );
    return linhas.map(paraPlano);
  }

  async criar(organizacaoId: string, dados: SalvarPlanoDto): Promise<Plano> {
    const [linha] = await comUnico(NOME_REPETIDO, () =>
      this.banco.consultar<LinhaPlano>(
        `INSERT INTO plano_associacao (organizacao_id, nome, valor_referencia, duracao_dias, cor)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING ${COLUNAS}`,
        [
          organizacaoId,
          dados.nome,
          dados.valorReferencia,
          dados.duracaoDias,
          dados.cor ?? null,
        ],
      ),
    );
    return paraPlano(linha);
  }

  async editar(
    organizacaoId: string,
    id: string,
    dados: SalvarPlanoDto,
    usuario: UsuarioLogado,
  ): Promise<Plano> {
    const [linhaAntes] = await this.banco.consultar<LinhaPlano>(
      `SELECT ${COLUNAS} FROM plano_associacao WHERE organizacao_id = $1 AND id = $2`,
      [organizacaoId, id],
    );
    if (!linhaAntes) throw new NotFoundException('Plano não encontrado.');
    const antes = paraPlano(linhaAntes);

    // RF16: a edição de plano entra na auditoria, junto com a alteração.
    const [linha] = await comUnico(NOME_REPETIDO, () =>
      this.banco.transacao(async (consultar) => {
        const linhas = await consultar<LinhaPlano>(
          `UPDATE plano_associacao
           SET nome = $3, valor_referencia = $4, duracao_dias = $5, cor = $6
           WHERE organizacao_id = $1 AND id = $2
           RETURNING ${COLUNAS}`,
          [
            organizacaoId,
            id,
            dados.nome,
            dados.valorReferencia,
            dados.duracaoDias,
            dados.cor ?? null,
          ],
        );
        const mudancas = descreverMudancas(antes, paraPlano(linhas[0]));
        if (mudancas) {
          await registrarAuditoria(consultar, usuario, {
            acao: 'EDICAO_PLANO',
            entidade: 'plano',
            entidadeId: id,
            descricao: `Plano ${antes.nome} editado: ${mudancas}.`,
          });
        }
        return linhas;
      }),
    );
    return paraPlano(linha);
  }

  // Desativar só impede novos vínculos; os membros do plano não são afetados.
  async alterarStatus(
    organizacaoId: string,
    id: string,
    status: Plano['status'],
  ): Promise<Plano> {
    const [linha] = await this.banco.consultar<LinhaPlano>(
      `UPDATE plano_associacao SET status = $3
       WHERE organizacao_id = $1 AND id = $2
       RETURNING ${COLUNAS}`,
      [organizacaoId, id, status],
    );
    if (!linha) throw new NotFoundException('Plano não encontrado.');
    return paraPlano(linha);
  }
}

function paraPlano(linha: LinhaPlano): Plano {
  return {
    id: linha.id,
    nome: linha.nome,
    // O pg devolve NUMERIC como texto para não perder precisão.
    valorReferencia: Number(linha.valor_referencia),
    duracaoDias: linha.duracao_dias,
    cor: linha.cor,
    status: linha.status,
  };
}

// "valor R$ 89,90 → R$ 99,90; duração 30 → 31 dias", ou '' se nada mudou.
function descreverMudancas(antes: Plano, depois: Plano) {
  const reais = (v: number) => `R$ ${v.toFixed(2).replace('.', ',')}`;
  const mudancas: string[] = [];
  if (antes.nome !== depois.nome) {
    mudancas.push(`nome ${antes.nome} → ${depois.nome}`);
  }
  if (antes.valorReferencia !== depois.valorReferencia) {
    mudancas.push(
      `valor ${reais(antes.valorReferencia)} → ${reais(depois.valorReferencia)}`,
    );
  }
  if (antes.cor !== depois.cor) {
    mudancas.push(`cor ${antes.cor ?? 'padrão'} → ${depois.cor ?? 'padrão'}`);
  }
  if (antes.duracaoDias !== depois.duracaoDias) {
    mudancas.push(`duração ${antes.duracaoDias} → ${depois.duracaoDias} dias`);
  }
  return mudancas.join('; ');
}
