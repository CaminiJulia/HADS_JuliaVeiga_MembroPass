import { randomInt } from 'node:crypto';
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { BancoService, Consulta } from '../banco/banco.service';
import { comUnico } from '../banco/erros';
import { SalvarMembroDto } from './dto/membro.dto';

export interface Membro {
  id: string;
  nome: string;
  email: string;
  telefone: string | null;
  planoId: string;
  planoNome: string;
  dataAdesao: string;
  status: 'ATIVO' | 'DESATIVADO' | 'CANCELADO';
  carteirinha: {
    status: 'ATIVA' | 'BLOQUEADA' | 'INVALIDADA';
    dataVencimento: string;
    qrVersao: number;
  };
}

interface LinhaMembro {
  id: string;
  nome: string;
  email: string;
  telefone: string | null;
  plano_id: string;
  plano_nome: string;
  data_adesao: string;
  status: Membro['status'];
  carteirinha_status: Membro['carteirinha']['status'];
  data_vencimento: string;
  qr_versao: number;
}

const SQL_MEMBROS = `
  SELECT m.id, m.nome, m.email, m.telefone, m.plano_id, p.nome AS plano_nome,
         m.data_adesao, m.status,
         c.status AS carteirinha_status, c.data_vencimento, c.qr_versao
  FROM membro m
  JOIN plano_associacao p ON p.id = m.plano_id
  JOIN carteirinha c ON c.membro_id = m.id
  WHERE m.organizacao_id = $1
`;

const EMAIL_EM_USO = 'Este e-mail já está em uso por outra conta.';

// Sem caracteres que se confundem (0/O, 1/l/I), para ditar ao membro.
const ALFABETO_SENHA =
  'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';

// RF06 e RF05. Sempre filtrado pela organização do token (multi-tenant).
@Injectable()
export class MembrosService {
  constructor(private readonly banco: BancoService) {}

  async listar(organizacaoId: string, busca?: string): Promise<Membro[]> {
    const termo = busca?.trim();
    const linhas = await this.banco.consultar<LinhaMembro>(
      termo
        ? `${SQL_MEMBROS} AND (m.nome ILIKE $2 OR m.email ILIKE $2) ORDER BY m.nome`
        : `${SQL_MEMBROS} ORDER BY m.nome`,
      termo ? [organizacaoId, `%${termo}%`] : [organizacaoId],
    );
    return linhas.map(paraMembro);
  }

  async buscar(organizacaoId: string, id: string): Promise<Membro> {
    const [linha] = await this.banco.consultar<LinhaMembro>(
      `${SQL_MEMBROS} AND m.id = $2`,
      [organizacaoId, id],
    );
    if (!linha) throw new NotFoundException('Membro não encontrado.');
    return paraMembro(linha);
  }

  // Cria o membro com uma senha provisória, devolvida só nesta resposta para
  // o administrador repassar. A carteirinha é emitida por trigger no banco.
  async criar(organizacaoId: string, dados: SalvarMembroDto) {
    await exigirPlanoAtivo(this.banco.consultar, organizacaoId, dados.planoId);
    const senhaProvisoria = gerarSenha();
    const senhaHash = await bcrypt.hash(senhaProvisoria, 10);

    const [{ id }] = await comUnico(EMAIL_EM_USO, () =>
      this.banco.consultar<{ id: string }>(
        `INSERT INTO membro (organizacao_id, nome, email, senha_hash, telefone, plano_id)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id`,
        [
          organizacaoId,
          dados.nome,
          dados.email,
          senhaHash,
          dados.telefone ?? null,
          dados.planoId,
        ],
      ),
    );
    return { membro: await this.buscar(organizacaoId, id), senhaProvisoria };
  }

  // Trocar de plano não muda o vencimento atual; o novo plano vale a partir
  // da próxima liberação de ciclo.
  async editar(organizacaoId: string, id: string, dados: SalvarMembroDto) {
    const atual = await this.buscar(organizacaoId, id);
    if (dados.planoId !== atual.planoId) {
      await exigirPlanoAtivo(
        this.banco.consultar,
        organizacaoId,
        dados.planoId,
      );
    }
    await comUnico(EMAIL_EM_USO, () =>
      this.banco.consultar(
        `UPDATE membro SET nome = $3, email = $4, telefone = $5, plano_id = $6
         WHERE organizacao_id = $1 AND id = $2`,
        [
          organizacaoId,
          id,
          dados.nome,
          dados.email,
          dados.telefone ?? null,
          dados.planoId,
        ],
      ),
    );
    return this.buscar(organizacaoId, id);
  }

  // Desativar invalida a carteirinha; reativar volta a deixá-la ativa.
  async alterarStatus(
    organizacaoId: string,
    id: string,
    status: 'ATIVO' | 'DESATIVADO',
  ) {
    await this.banco.transacao(async (consultar) => {
      const linhas = await consultar(
        `UPDATE membro SET status = $3
         WHERE organizacao_id = $1 AND id = $2 AND status <> 'CANCELADO'
         RETURNING id`,
        [organizacaoId, id, status],
      );
      if (linhas.length === 0) {
        throw new NotFoundException('Membro não encontrado.');
      }
      await consultar(
        `UPDATE carteirinha
         SET status = $2, qr_versao = qr_versao + 1
         WHERE membro_id = $1`,
        [id, status === 'ATIVO' ? 'ATIVA' : 'INVALIDADA'],
      );
    });
    return this.buscar(organizacaoId, id);
  }
}

async function exigirPlanoAtivo(
  consultar: Consulta,
  organizacaoId: string,
  planoId: string,
) {
  const [plano] = await consultar<{ status: string }>(
    'SELECT status FROM plano_associacao WHERE organizacao_id = $1 AND id = $2',
    [organizacaoId, planoId],
  );
  if (!plano) throw new BadRequestException('Plano não encontrado.');
  if (plano.status !== 'ATIVO') {
    throw new BadRequestException(
      'Este plano está desativado e não aceita novos membros.',
    );
  }
}

function gerarSenha(tamanho = 8) {
  return Array.from(
    { length: tamanho },
    () => ALFABETO_SENHA[randomInt(ALFABETO_SENHA.length)],
  ).join('');
}

function paraMembro(linha: LinhaMembro): Membro {
  return {
    id: linha.id,
    nome: linha.nome,
    email: linha.email,
    telefone: linha.telefone,
    planoId: linha.plano_id,
    planoNome: linha.plano_nome,
    dataAdesao: linha.data_adesao,
    status: linha.status,
    carteirinha: {
      status: linha.carteirinha_status,
      dataVencimento: linha.data_vencimento,
      qrVersao: linha.qr_versao,
    },
  };
}
