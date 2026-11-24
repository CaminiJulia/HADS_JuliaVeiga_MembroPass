import { randomInt } from 'node:crypto';
import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { BancoService } from '../banco/banco.service';
import { EmailService } from '../email/email.service';
import { definirSenha, emitirToken, TABELA_DA_CONTA } from './contas';
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
  // Senha gerada pelo administrador: o app pede uma nova antes de seguir.
  senhaProvisoria: boolean;
}

interface LinhaConta {
  id: string;
  nome: string;
  email: string;
  senha_hash: string;
  papel: Papel;
  organizacao_id: string;
  organizacao_nome: string;
  senha_provisoria: boolean;
  versao_sessao: number;
}

// O papel é descoberto pelo cadastro em que o e-mail for encontrado (RF01).
// Só entram contas ativas de organizações que não estão suspensas.
const SQL_BUSCAR_CONTA = `
  SELECT c.id, c.nome, c.email, c.senha_hash, c.papel, c.organizacao_id,
         c.senha_provisoria, c.versao_sessao, o.nome AS organizacao_nome
  FROM (
    SELECT id, nome, email, senha_hash, senha_provisoria, versao_sessao, organizacao_id, 'administrador' AS papel
    FROM administrador WHERE status = 'ATIVO'
    UNION ALL
    SELECT id, nome, email, senha_hash, senha_provisoria, versao_sessao, organizacao_id, 'operador'
    FROM operador WHERE status = 'ATIVO'
    UNION ALL
    SELECT id, nome, email, senha_hash, senha_provisoria, versao_sessao, organizacao_id, 'membro'
    FROM membro WHERE status = 'ATIVO'
  ) c
  JOIN organizacao o ON o.id = c.organizacao_id AND o.status <> 'SUSPENSA'
  WHERE lower(c.email) = lower($1)
`;

// Comparado quando o e-mail não existe, para a resposta levar o mesmo tempo
// e não revelar quais e-mails estão cadastrados.
const HASH_FALSO =
  '$2b$10$swt93Y0d1fTr4hvjd3wBQOuZTq9fKiOwJjl4/TSXpC.xVg3yFcIXX';

// Código de recuperação de senha (HU03).
const VALIDADE_CODIGO_MIN = 15;
const MAXIMO_TENTATIVAS_CODIGO = 5;
const CODIGO_INVALIDO = 'Código inválido ou vencido. Peça um novo código.';

@Injectable()
export class AuthService {
  private readonly limitador = new LimitadorTentativas();

  constructor(
    private readonly banco: BancoService,
    private readonly jwt: JwtService,
    private readonly email: EmailService,
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
      senhaProvisoria: conta.senha_provisoria,
    };
    const token = await emitirToken(this.jwt, usuario, conta.versao_sessao);
    return { token, usuario };
  }

  // Troca a senha de quem está logado (qualquer papel). Derruba as outras
  // sessões e devolve um token novo, para esta continuar.
  async trocarSenha(
    conta: { id: string; papel: Papel; organizacaoId: string },
    senhaAtual: string,
    novaSenha: string,
  ) {
    const [linha] = await this.banco.consultar<{ senha_hash: string }>(
      `SELECT senha_hash FROM ${TABELA_DA_CONTA[conta.papel]} WHERE id = $1 AND status = 'ATIVO'`,
      [conta.id],
    );
    if (!linha) throw new NotFoundException('Conta não encontrada.');
    if (!(await bcrypt.compare(senhaAtual, linha.senha_hash))) {
      throw new BadRequestException('A senha atual está incorreta.');
    }
    if (senhaAtual === novaSenha) {
      throw new BadRequestException(
        'A nova senha precisa ser diferente da atual.',
      );
    }
    const versao = await definirSenha(
      this.banco.consultar,
      conta.papel,
      conta.id,
      novaSenha,
      { provisoria: false },
    );
    return { token: await emitirToken(this.jwt, conta, versao) };
  }

  // HU03: manda um código de 6 dígitos para o e-mail. A resposta é sempre a
  // mesma, exista ou não a conta, para não revelar quem está cadastrado.
  async solicitarRecuperacaoSenha(email: string) {
    const contas = await this.banco.consultar<LinhaConta>(SQL_BUSCAR_CONTA, [
      email.trim(),
    ]);
    const conta = contas[0];
    if (!conta) return;

    const codigo = String(randomInt(0, 1_000_000)).padStart(6, '0');
    await this.banco.transacao(async (consultar) => {
      // Um código novo anula os anteriores ainda não usados.
      await consultar(
        `UPDATE recuperacao_senha SET usado_em = now()
         WHERE lower(email) = lower($1) AND usado_em IS NULL`,
        [conta.email],
      );
      await consultar(
        `INSERT INTO recuperacao_senha (email, codigo_hash, expira_em)
         VALUES ($1, $2, now() + make_interval(mins => $3))`,
        [conta.email, await bcrypt.hash(codigo, 10), VALIDADE_CODIGO_MIN],
      );
    });
    await this.email.enviarCodigoRecuperacao(conta.email, conta.nome, codigo);
  }

  // Confere o código e grava a nova senha. Cada erro conta uma tentativa;
  // na quinta, o código deixa de valer.
  async redefinirSenha(email: string, codigo: string, novaSenha: string) {
    const [pedido] = await this.banco.consultar<{
      id: string;
      codigo_hash: string;
      tentativas: number;
    }>(
      `SELECT id, codigo_hash, tentativas FROM recuperacao_senha
       WHERE lower(email) = lower($1) AND usado_em IS NULL AND expira_em > now()
       ORDER BY criado_em DESC LIMIT 1`,
      [email.trim()],
    );
    if (!pedido || pedido.tentativas >= MAXIMO_TENTATIVAS_CODIGO) {
      throw new BadRequestException(CODIGO_INVALIDO);
    }
    if (!(await bcrypt.compare(codigo, pedido.codigo_hash))) {
      await this.banco.consultar(
        'UPDATE recuperacao_senha SET tentativas = tentativas + 1 WHERE id = $1',
        [pedido.id],
      );
      throw new BadRequestException(
        'Código incorreto. Confira o e-mail e tente de novo.',
      );
    }

    const contas = await this.banco.consultar<LinhaConta>(SQL_BUSCAR_CONTA, [
      email.trim(),
    ]);
    if (contas.length === 0) throw new BadRequestException(CODIGO_INVALIDO);
    await this.banco.transacao(async (consultar) => {
      await consultar(
        'UPDATE recuperacao_senha SET usado_em = now() WHERE id = $1',
        [pedido.id],
      );
      for (const conta of contas) {
        await definirSenha(consultar, conta.papel, conta.id, novaSenha, {
          provisoria: false,
        });
      }
    });
    // Quem estava bloqueado por errar a senha pode entrar de novo.
    this.limitador.limpar(email);
  }

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
