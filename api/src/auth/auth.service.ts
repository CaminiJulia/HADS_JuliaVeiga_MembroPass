import {
  HttpException,
  HttpStatus,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { BancoService } from '../banco/banco.service';
import { LimitadorTentativas } from './limitador-tentativas';

// Os três papéis da plataforma (RF02), com os mesmos nomes do app.
export type Papel = 'administrador' | 'operador' | 'membro';

export interface UsuarioAutenticado {
  id: string;
  nome: string;
  email: string;
  papel: Papel;
  organizacaoId: string;
  organizacaoNome: string;
}

interface LinhaConta {
  id: string;
  nome: string;
  email: string;
  senha_hash: string;
  papel: Papel;
  organizacao_id: string;
  organizacao_nome: string;
}

// O papel é descoberto pelo cadastro em que o e-mail for encontrado (RF01).
// Só entram contas ativas de organizações que não estão suspensas.
const SQL_BUSCAR_CONTA = `
  SELECT c.id, c.nome, c.email, c.senha_hash, c.papel, c.organizacao_id,
         o.nome AS organizacao_nome
  FROM (
    SELECT id, nome, email, senha_hash, organizacao_id, 'administrador' AS papel
    FROM administrador WHERE status = 'ATIVO'
    UNION ALL
    SELECT id, nome, email, senha_hash, organizacao_id, 'operador'
    FROM operador WHERE status = 'ATIVO'
    UNION ALL
    SELECT id, nome, email, senha_hash, organizacao_id, 'membro'
    FROM membro WHERE status = 'ATIVO'
  ) c
  JOIN organizacao o ON o.id = c.organizacao_id AND o.status <> 'SUSPENSA'
  WHERE lower(c.email) = lower($1)
`;

// Comparado quando o e-mail não existe, para a resposta levar o mesmo tempo
// e não revelar quais e-mails estão cadastrados.
const HASH_FALSO =
  '$2b$10$swt93Y0d1fTr4hvjd3wBQOuZTq9fKiOwJjl4/TSXpC.xVg3yFcIXX';

@Injectable()
export class AuthService {
  private readonly limitador = new LimitadorTentativas();

  constructor(
    private readonly banco: BancoService,
    private readonly jwt: JwtService,
  ) {}

  async entrar(email: string, senha: string) {
    const restante = this.limitador.tempoRestante(email);
    if (restante !== null) {
      const segundos = Math.ceil(restante / 1000);
      throw new HttpException(
        `Muitas tentativas sem sucesso. Tente novamente em ${segundos} segundos.`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const contas = await this.banco.consultar<LinhaConta>(SQL_BUSCAR_CONTA, [
      email.trim(),
    ]);
    const conta = await this.contaComSenhaCorreta(contas, senha);
    if (!conta) {
      this.limitador.registrarFalha(email);
      throw new UnauthorizedException('E-mail ou senha incorretos.');
    }

    this.limitador.limpar(email);
    const usuario: UsuarioAutenticado = {
      id: conta.id,
      nome: conta.nome,
      email: conta.email,
      papel: conta.papel,
      organizacaoId: conta.organizacao_id,
      organizacaoNome: conta.organizacao_nome,
    };
    const token = await this.jwt.signAsync({
      sub: usuario.id,
      papel: usuario.papel,
      organizacaoId: usuario.organizacaoId,
    });
    return { token, usuario };
  }

  // HU03: o envio de e-mail chega numa próxima etapa. A resposta é sempre
  // a mesma, exista ou não o cadastro, para não revelar e-mails da base.
  async solicitarRecuperacaoSenha(): Promise<void> {}

  // O mesmo e-mail pode estar em mais de um cadastro (ex.: operador que também
  // é membro); entra a primeira conta cuja senha confere.
  private async contaComSenhaCorreta(contas: LinhaConta[], senha: string) {
    if (contas.length === 0) {
      await bcrypt.compare(senha, HASH_FALSO);
      return null;
    }
    for (const conta of contas) {
      if (await bcrypt.compare(senha, conta.senha_hash)) return conta;
    }
    return null;
  }
}
