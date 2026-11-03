import { randomInt } from 'node:crypto';
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { DatabaseError } from 'pg';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { listarAuditoria, registrarAuditoria } from '../auditoria/auditoria';
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
  planoDuracaoDias: number;
  planoCor: string | null;
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
  plano_duracao_dias: number;
  plano_cor: string | null;
  data_adesao: string;
  status: Membro['status'];
  carteirinha_status: Membro['carteirinha']['status'];
  data_vencimento: string;
  qr_versao: number;
}

const SQL_MEMBROS = `
  SELECT m.id, m.nome, m.email, m.telefone, m.plano_id, p.nome AS plano_nome,
         p.duracao_dias AS plano_duracao_dias, p.cor AS plano_cor, m.data_adesao, m.status,
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
  // Fica registrado na auditoria (RF16).
  async alterarStatus(
    usuario: UsuarioLogado,
    id: string,
    status: 'ATIVO' | 'DESATIVADO',
    justificativa?: string | null,
  ) {
    const membro = await this.buscar(usuario.organizacaoId, id);
    if (membro.status === 'CANCELADO') {
      throw new BadRequestException('Este membro teve a associação cancelada.');
    }
    if ((membro.status === 'ATIVO') === (status === 'ATIVO')) return membro;

    await this.banco.transacao(async (consultar) => {
      await consultar('UPDATE membro SET status = $2 WHERE id = $1', [
        id,
        status,
      ]);
      await consultar(
        `UPDATE carteirinha SET status = $2, qr_versao = qr_versao + 1
         WHERE membro_id = $1`,
        [id, status === 'ATIVO' ? 'ATIVA' : 'INVALIDADA'],
      );
      await registrarAuditoria(consultar, usuario, {
        acao: status === 'ATIVO' ? 'REATIVACAO_MEMBRO' : 'DESATIVACAO_MEMBRO',
        entidade: 'membro',
        entidadeId: id,
        descricao:
          status === 'ATIVO'
            ? `Cadastro de ${membro.nome} reativado.`
            : `Cadastro de ${membro.nome} desativado; a carteirinha foi invalidada.`,
        justificativa,
      });
    });
    return this.buscar(usuario.organizacaoId, id);
  }

  // RF07: confirmação manual do pagamento, pela função liberar_ciclo do banco
  // (calcula o vencimento, reativa a carteirinha e grava a auditoria).
  async liberarCiclo(
    usuario: UsuarioLogado,
    id: string,
    dataPagamento: string,
  ) {
    const membro = await this.buscar(usuario.organizacaoId, id);
    if (membro.status !== 'ATIVO') {
      throw new BadRequestException(
        'Reative o membro antes de confirmar um pagamento.',
      );
    }
    try {
      await this.banco.consultar('SELECT liberar_ciclo($1, $2, $3)', [
        id,
        usuario.id,
        dataPagamento,
      ]);
    } catch (erro) {
      // As validações da função chegam como RAISE EXCEPTION (código P0001).
      if (erro instanceof DatabaseError && erro.code === 'P0001') {
        throw new BadRequestException(erro.message);
      }
      throw erro;
    }
    return this.buscar(usuario.organizacaoId, id);
  }

  // RF07: bloqueio manual. O sistema nunca bloqueia sozinho; a justificativa
  // é obrigatória e fica na auditoria. A nova versão invalida o QR antigo.
  bloquear(usuario: UsuarioLogado, id: string, justificativa: string) {
    return this.alterarBloqueio(usuario, id, true, justificativa);
  }

  desbloquear(
    usuario: UsuarioLogado,
    id: string,
    justificativa?: string | null,
  ) {
    return this.alterarBloqueio(usuario, id, false, justificativa);
  }

  historico(organizacaoId: string, id: string) {
    return listarAuditoria(this.banco.consultar, organizacaoId, id);
  }

  private async alterarBloqueio(
    usuario: UsuarioLogado,
    id: string,
    bloquear: boolean,
    justificativa?: string | null,
  ) {
    const membro = await this.buscar(usuario.organizacaoId, id);
    if (membro.status !== 'ATIVO') {
      throw new BadRequestException('Este membro está desativado.');
    }
    if ((membro.carteirinha.status === 'BLOQUEADA') === bloquear) {
      throw new BadRequestException(
        bloquear
          ? 'A carteirinha já está bloqueada.'
          : 'A carteirinha não está bloqueada.',
      );
    }

    await this.banco.transacao(async (consultar) => {
      await consultar(
        `UPDATE carteirinha SET status = $2, qr_versao = qr_versao + 1
         WHERE membro_id = $1`,
        [id, bloquear ? 'BLOQUEADA' : 'ATIVA'],
      );
      await registrarAuditoria(consultar, usuario, {
        acao: bloquear ? 'BLOQUEIO_MANUAL' : 'DESBLOQUEIO',
        entidade: 'membro',
        entidadeId: id,
        descricao: bloquear
          ? `Carteirinha de ${membro.nome} bloqueada.`
          : `Carteirinha de ${membro.nome} desbloqueada.`,
        justificativa,
      });
    });
    return this.buscar(usuario.organizacaoId, id);
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
    planoDuracaoDias: linha.plano_duracao_dias,
    planoCor: linha.plano_cor,
    dataAdesao: linha.data_adesao,
    status: linha.status,
    carteirinha: {
      status: linha.carteirinha_status,
      dataVencimento: linha.data_vencimento,
      qrVersao: linha.qr_versao,
    },
  };
}
