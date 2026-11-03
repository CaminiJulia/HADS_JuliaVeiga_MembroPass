import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BancoService } from '../banco/banco.service';
import { vincularPlanos } from '../planos/vincular-planos';
import { SalvarUnidadeEventoDto } from './dto/unidade-evento.dto';

export interface UnidadeEvento {
  id: string;
  nome: string;
  tipo: 'UNIDADE' | 'EVENTO';
  localizacao: string | null;
  dataInicio: string | null;
  dataFim: string | null;
  planoIds: string[];
}

interface LinhaUnidadeEvento {
  id: string;
  nome: string;
  tipo: 'UNIDADE' | 'EVENTO';
  localizacao: string | null;
  data_inicio: string | null;
  data_fim: string | null;
  plano_ids: string[];
}

const SQL_LISTAR = `
  SELECT u.id, u.nome, u.tipo, u.localizacao, u.data_inicio, u.data_fim,
         COALESCE(array_agg(up.plano_id) FILTER (WHERE up.plano_id IS NOT NULL), '{}') AS plano_ids
  FROM unidade_evento u
  LEFT JOIN unidade_evento_plano up ON up.unidade_evento_id = u.id
  WHERE u.organizacao_id = $1
`;

// RF11. Sempre filtrado pela organização do token (multi-tenant).
@Injectable()
export class UnidadesService {
  constructor(private readonly banco: BancoService) {}

  async listar(organizacaoId: string): Promise<UnidadeEvento[]> {
    const linhas = await this.banco.consultar<LinhaUnidadeEvento>(
      `${SQL_LISTAR} GROUP BY u.id ORDER BY u.tipo DESC, u.data_inicio NULLS FIRST, u.nome`,
      [organizacaoId],
    );
    return linhas.map(paraUnidadeEvento);
  }

  async criar(organizacaoId: string, dados: SalvarUnidadeEventoDto) {
    const valores = validarPeriodo(dados);
    const id = await this.banco.transacao(async (consultar) => {
      const [{ id }] = await consultar<{ id: string }>(
        `INSERT INTO unidade_evento (organizacao_id, nome, tipo, localizacao, data_inicio, data_fim)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id`,
        [organizacaoId, ...valores],
      );
      await vincularPlanos(
        consultar,
        'unidadeEvento',
        organizacaoId,
        id,
        dados.planoIds,
      );
      return id;
    });
    return this.buscar(organizacaoId, id);
  }

  async editar(
    organizacaoId: string,
    id: string,
    dados: SalvarUnidadeEventoDto,
  ) {
    const valores = validarPeriodo(dados);
    await this.banco.transacao(async (consultar) => {
      const linhas = await consultar(
        `UPDATE unidade_evento
         SET nome = $3, tipo = $4, localizacao = $5, data_inicio = $6, data_fim = $7
         WHERE organizacao_id = $1 AND id = $2
         RETURNING id`,
        [organizacaoId, id, ...valores],
      );
      if (linhas.length === 0) {
        throw new NotFoundException('Unidade ou evento não encontrado.');
      }
      await vincularPlanos(
        consultar,
        'unidadeEvento',
        organizacaoId,
        id,
        dados.planoIds,
      );
    });
    return this.buscar(organizacaoId, id);
  }

  async excluir(organizacaoId: string, id: string) {
    const linhas = await this.banco.consultar(
      'DELETE FROM unidade_evento WHERE organizacao_id = $1 AND id = $2 RETURNING id',
      [organizacaoId, id],
    );
    if (linhas.length === 0) {
      throw new NotFoundException('Unidade ou evento não encontrado.');
    }
  }

  private async buscar(organizacaoId: string, id: string) {
    const [linha] = await this.banco.consultar<LinhaUnidadeEvento>(
      `${SQL_LISTAR} AND u.id = $2 GROUP BY u.id`,
      [organizacaoId, id],
    );
    return paraUnidadeEvento(linha);
  }
}

// Evento exige início e fim, com o fim depois do início; unidade não tem datas.
function validarPeriodo(dados: SalvarUnidadeEventoDto) {
  if (dados.tipo === 'EVENTO') {
    if (!dados.dataInicio || !dados.dataFim) {
      throw new BadRequestException('Informe o início e o fim do evento.');
    }
    if (dados.dataFim < dados.dataInicio) {
      throw new BadRequestException(
        'O fim do evento não pode ser antes do início.',
      );
    }
  }
  const evento = dados.tipo === 'EVENTO';
  return [
    dados.nome,
    dados.tipo,
    dados.localizacao ?? null,
    evento ? dados.dataInicio : null,
    evento ? dados.dataFim : null,
  ];
}

function paraUnidadeEvento(linha: LinhaUnidadeEvento): UnidadeEvento {
  return {
    id: linha.id,
    nome: linha.nome,
    tipo: linha.tipo,
    localizacao: linha.localizacao,
    dataInicio: linha.data_inicio,
    dataFim: linha.data_fim,
    planoIds: linha.plano_ids,
  };
}
