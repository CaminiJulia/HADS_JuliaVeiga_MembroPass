import { Injectable } from '@nestjs/common';
import { StatusCadastro, StatusMembro, StatusOrganizacao } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { Papel } from './papel.js';

// Visão única dos três cadastros de acesso, que no banco são tabelas
// independentes: administrador, operador e membro (DVP v2.6).
export interface Conta {
  id: string;
  papel: Papel;
  organizacaoId: string;
  nome: string;
  email: string;
  senhaHash: string;
  ativa: boolean;
  organizacao: {
    id: string;
    nome: string;
    status: StatusOrganizacao;
    logoUrl: string | null;
    corPrincipal: string | null;
  };
}

// A identidade visual vai junto para o app aplicar o tema da organização (RF17).
const comOrganizacao = {
  organizacao: {
    select: { id: true, nome: true, status: true, logoUrl: true, corPrincipal: true },
  },
} as const;

type Cadastro = Omit<Conta, 'papel' | 'ativa'> & { status: StatusCadastro | StatusMembro };

function paraConta(papel: Papel, { status, ...cadastro }: Cadastro): Conta {
  const { id, organizacaoId, nome, email, senhaHash, organizacao } = cadastro;
  return { id, organizacaoId, nome, email, senhaHash, organizacao, papel, ativa: status === 'ATIVO' };
}

@Injectable()
export class ContasService {
  constructor(private readonly prisma: PrismaService) {}

  // RF01: localiza o e-mail entre os três cadastros. A trigger
  // fn_email_unico_entre_cadastros garante que ele está em no máximo um.
  async buscarPorEmail(email: string): Promise<Conta | null> {
    const consulta = { where: { email }, include: comOrganizacao };
    const [administrador, operador, membro] = await Promise.all([
      this.prisma.administrador.findUnique(consulta),
      this.prisma.operador.findUnique(consulta),
      this.prisma.membro.findUnique(consulta),
    ]);
    if (administrador) return paraConta(Papel.ADMINISTRADOR, administrador);
    if (operador) return paraConta(Papel.OPERADOR, operador);
    if (membro) return paraConta(Papel.MEMBRO, membro);
    return null;
  }

  async buscarPorId(papel: Papel, id: string): Promise<Conta | null> {
    const consulta = { where: { id }, include: comOrganizacao };
    switch (papel) {
      case Papel.ADMINISTRADOR: {
        const cadastro = await this.prisma.administrador.findUnique(consulta);
        return cadastro && paraConta(papel, cadastro);
      }
      case Papel.OPERADOR: {
        const cadastro = await this.prisma.operador.findUnique(consulta);
        return cadastro && paraConta(papel, cadastro);
      }
      case Papel.MEMBRO: {
        const cadastro = await this.prisma.membro.findUnique(consulta);
        return cadastro && paraConta(papel, cadastro);
      }
      default:
        return null;
    }
  }
}
