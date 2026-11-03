import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BancoService } from '../banco/banco.service';
import { vincularPlanos } from '../planos/vincular-planos';
import { SalvarBeneficioDto } from './dto/beneficio.dto';

export interface Beneficio {
  id: string;
  nome: string;
  descricao: string | null;
  parceiro: string | null;
  tipoDesconto: 'PERCENTUAL' | 'VALOR';
  valorDesconto: number;
  vigInicio: string | null;
  vigFim: string | null;
  planoIds: string[];
}

interface LinhaBeneficio {
  id: string;
  nome: string;
  descricao: string | null;
  parceiro: string | null;
  tipo_desconto: 'PERCENTUAL' | 'VALOR';
  valor_desconto: string;
  vig_inicio: string | null;
  vig_fim: string | null;
  plano_ids: string[];
}

const SQL_LISTAR = `
  SELECT b.id, b.nome, b.descricao, b.parceiro, b.tipo_desconto, b.valor_desconto,
         b.vig_inicio, b.vig_fim,
         COALESCE(array_agg(pb.plano_id) FILTER (WHERE pb.plano_id IS NOT NULL), '{}') AS plano_ids
  FROM beneficio b
  LEFT JOIN plano_beneficio pb ON pb.beneficio_id = b.id
  WHERE b.organizacao_id = $1
`;

// RF08. Sempre filtrado pela organização do token (multi-tenant).
@Injectable()
export class BeneficiosService {
  constructor(private readonly banco: BancoService) {}

  async listar(organizacaoId: string): Promise<Beneficio[]> {
    const linhas = await this.banco.consultar<LinhaBeneficio>(
      `${SQL_LISTAR} GROUP BY b.id ORDER BY b.nome`,
      [organizacaoId],
    );
    return linhas.map(paraBeneficio);
  }

  async criar(organizacaoId: string, dados: SalvarBeneficioDto) {
    validarDesconto(dados);
    const id = await this.banco.transacao(async (consultar) => {
      const [{ id }] = await consultar<{ id: string }>(
        `INSERT INTO beneficio (organizacao_id, nome, descricao, parceiro, tipo_desconto,
                                valor_desconto, vig_inicio, vig_fim)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id`,
        [organizacaoId, ...colunas(dados)],
      );
      await vincularPlanos(
        consultar,
        'beneficio',
        organizacaoId,
        id,
        dados.planoIds,
      );
      return id;
    });
    return this.buscar(organizacaoId, id);
  }

  async editar(organizacaoId: string, id: string, dados: SalvarBeneficioDto) {
    validarDesconto(dados);
    await this.banco.transacao(async (consultar) => {
      const linhas = await consultar(
        `UPDATE beneficio
         SET nome = $3, descricao = $4, parceiro = $5, tipo_desconto = $6,
             valor_desconto = $7, vig_inicio = $8, vig_fim = $9
         WHERE organizacao_id = $1 AND id = $2
         RETURNING id`,
        [organizacaoId, id, ...colunas(dados)],
      );
      if (linhas.length === 0) {
        throw new NotFoundException('Benefício não encontrado.');
      }
      await vincularPlanos(
        consultar,
        'beneficio',
        organizacaoId,
        id,
        dados.planoIds,
      );
    });
    return this.buscar(organizacaoId, id);
  }

  async excluir(organizacaoId: string, id: string) {
    const linhas = await this.banco.consultar(
      'DELETE FROM beneficio WHERE organizacao_id = $1 AND id = $2 RETURNING id',
      [organizacaoId, id],
    );
    if (linhas.length === 0) {
      throw new NotFoundException('Benefício não encontrado.');
    }
  }

  private async buscar(organizacaoId: string, id: string) {
    const [linha] = await this.banco.consultar<LinhaBeneficio>(
      `${SQL_LISTAR} AND b.id = $2 GROUP BY b.id`,
      [organizacaoId, id],
    );
    return paraBeneficio(linha);
  }
}

function colunas(dados: SalvarBeneficioDto) {
  return [
    dados.nome,
    dados.descricao ?? null,
    dados.parceiro ?? null,
    dados.tipoDesconto,
    dados.valorDesconto,
    dados.vigInicio ?? null,
    dados.vigFim ?? null,
  ];
}

function validarDesconto(dados: SalvarBeneficioDto) {
  if (dados.tipoDesconto === 'PERCENTUAL' && dados.valorDesconto > 100) {
    throw new BadRequestException('O desconto percentual vai até 100%.');
  }
  if (dados.vigInicio && dados.vigFim && dados.vigFim < dados.vigInicio) {
    throw new BadRequestException(
      'O fim da vigência não pode ser antes do início.',
    );
  }
}

function paraBeneficio(linha: LinhaBeneficio): Beneficio {
  return {
    id: linha.id,
    nome: linha.nome,
    descricao: linha.descricao,
    parceiro: linha.parceiro,
    tipoDesconto: linha.tipo_desconto,
    valorDesconto: Number(linha.valor_desconto),
    vigInicio: linha.vig_inicio,
    vigFim: linha.vig_fim,
    planoIds: linha.plano_ids,
  };
}
