import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseError } from 'pg';
import { BancoService } from '../banco/banco.service';
import { SalvarPlanoDto } from './dto/plano.dto';

export interface Plano {
  id: string;
  nome: string;
  valorReferencia: number;
  duracaoDias: number;
  status: 'ATIVO' | 'INATIVO';
}

interface LinhaPlano {
  id: string;
  nome: string;
  valor_referencia: string;
  duracao_dias: number;
  status: 'ATIVO' | 'INATIVO';
}

const COLUNAS = 'id, nome, valor_referencia, duracao_dias, status';

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
    const [linha] = await this.comNomeUnico(() =>
      this.banco.consultar<LinhaPlano>(
        `INSERT INTO plano_associacao (organizacao_id, nome, valor_referencia, duracao_dias)
         VALUES ($1, $2, $3, $4)
         RETURNING ${COLUNAS}`,
        [organizacaoId, dados.nome, dados.valorReferencia, dados.duracaoDias],
      ),
    );
    return paraPlano(linha);
  }

  async editar(
    organizacaoId: string,
    id: string,
    dados: SalvarPlanoDto,
  ): Promise<Plano> {
    const [linha] = await this.comNomeUnico(() =>
      this.banco.consultar<LinhaPlano>(
        `UPDATE plano_associacao
         SET nome = $3, valor_referencia = $4, duracao_dias = $5
         WHERE organizacao_id = $1 AND id = $2
         RETURNING ${COLUNAS}`,
        [
          organizacaoId,
          id,
          dados.nome,
          dados.valorReferencia,
          dados.duracaoDias,
        ],
      ),
    );
    if (!linha) throw new NotFoundException('Plano não encontrado.');
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

  private async comNomeUnico<T>(operacao: () => Promise<T>): Promise<T> {
    try {
      return await operacao();
    } catch (erro) {
      if (erro instanceof DatabaseError && erro.code === '23505') {
        throw new ConflictException('Já existe um plano com esse nome.');
      }
      throw erro;
    }
  }
}

function paraPlano(linha: LinhaPlano): Plano {
  return {
    id: linha.id,
    nome: linha.nome,
    // O pg devolve NUMERIC como texto para não perder precisão.
    valorReferencia: Number(linha.valor_referencia),
    duracaoDias: linha.duracao_dias,
    status: linha.status,
  };
}
