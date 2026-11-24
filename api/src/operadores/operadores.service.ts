import { Injectable, NotFoundException } from '@nestjs/common';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { definirSenha } from '../auth/contas';
import { registrarAuditoria } from '../auditoria/auditoria';
import { BancoService } from '../banco/banco.service';
import { comUnico } from '../banco/erros';
import { Datas } from '../comum/datas';
import { gerarSenha } from '../comum/senha';
import { EmailService } from '../email/email.service';
import { SalvarOperadorDto } from './dto/operador.dto';

const EMAIL_EM_USO = 'Este e-mail já está em uso por outra conta.';

interface LinhaOperador {
  id: string;
  nome: string;
  email: string;
  telefone: string | null;
  status: 'ATIVO' | 'INATIVO';
  foto: Buffer | null;
  foto_tipo: string | null;
  checkins_hoje: number;
  ultimo_checkin: Date | null;
}

// Leituras de hoje e a última leitura de cada um, para o admin ver quem está
// trabalhando. A foto vem do perfil que o próprio operador mantém.
const SQL_OPERADORES = `
  SELECT op.id, op.nome, op.email, op.telefone, op.status, op.foto, op.foto_tipo,
         (SELECT count(*)::int FROM checkin ck
          WHERE ck.operador_id = op.id AND ck.data_hora >= $2::date) AS checkins_hoje,
         (SELECT max(ck.data_hora) FROM checkin ck WHERE ck.operador_id = op.id) AS ultimo_checkin
  FROM operador op
  WHERE op.organizacao_id = $1
`;

// Cadastro dos operadores pelo administrador (RF02). Sempre filtrado pela
// organização do token. Operador não é excluído, só desativado: os check-ins
// que ele registrou continuam apontando para ele. Toda ação vai para a
// auditoria (RF16).
@Injectable()
export class OperadoresService {
  constructor(
    private readonly banco: BancoService,
    private readonly email: EmailService,
  ) {}

  async listar(organizacaoId: string) {
    const linhas = await this.banco.consultar<LinhaOperador>(
      `${SQL_OPERADORES} ORDER BY op.status, op.nome`,
      [organizacaoId, Datas.hoje()],
    );
    return linhas.map(paraOperador);
  }

  async buscar(organizacaoId: string, id: string) {
    const [linha] = await this.banco.consultar<LinhaOperador>(
      `${SQL_OPERADORES} AND op.id = $3`,
      [organizacaoId, Datas.hoje(), id],
    );
    if (!linha) throw new NotFoundException('Operador não encontrado.');
    return paraOperador(linha);
  }

  // Cria com uma senha provisória, devolvida só nesta resposta e enviada por
  // e-mail. No primeiro login, o app pede uma senha nova.
  async criar(usuario: UsuarioLogado, dados: SalvarOperadorDto) {
    const senhaProvisoria = gerarSenha();
    const id = await comUnico(EMAIL_EM_USO, () =>
      this.banco.transacao(async (consultar) => {
        const [{ id }] = await consultar<{ id: string }>(
          `INSERT INTO operador (organizacao_id, nome, email, senha_hash, telefone)
           VALUES ($1, $2, $3, '', $4)
           RETURNING id`,
          [
            usuario.organizacaoId,
            dados.nome,
            dados.email,
            dados.telefone ?? null,
          ],
        );
        await definirSenha(consultar, 'operador', id, senhaProvisoria, {
          provisoria: true,
        });
        await registrarAuditoria(consultar, usuario, {
          acao: 'CADASTRO_OPERADOR',
          entidade: 'operador',
          entidadeId: id,
          descricao: `Operador ${dados.nome} (${dados.email}) cadastrado.`,
        });
        return id;
      }),
    );
    const operador = await this.buscar(usuario.organizacaoId, id);
    const emailEnviado = await this.enviarSenha(
      usuario.organizacaoId,
      operador,
      senhaProvisoria,
    );
    return { operador, senhaProvisoria, emailEnviado };
  }

  async editar(usuario: UsuarioLogado, id: string, dados: SalvarOperadorDto) {
    await comUnico(EMAIL_EM_USO, () =>
      this.banco.transacao(async (consultar) => {
        const linhas = await consultar(
          `UPDATE operador SET nome = $3, email = $4, telefone = $5
           WHERE organizacao_id = $1 AND id = $2
           RETURNING id`,
          [
            usuario.organizacaoId,
            id,
            dados.nome,
            dados.email,
            dados.telefone ?? null,
          ],
        );
        if (linhas.length === 0)
          throw new NotFoundException('Operador não encontrado.');
        await registrarAuditoria(consultar, usuario, {
          acao: 'EDICAO_OPERADOR',
          entidade: 'operador',
          entidadeId: id,
          descricao: `Dados do operador ${dados.nome} alterados.`,
        });
      }),
    );
    return this.buscar(usuario.organizacaoId, id);
  }

  // Inativo não consegue mais entrar, e a sessão aberta cai na hora (o guard
  // confere o status a cada requisição).
  async alterarStatus(
    usuario: UsuarioLogado,
    id: string,
    status: 'ATIVO' | 'INATIVO',
  ) {
    const atual = await this.buscar(usuario.organizacaoId, id);
    await this.banco.transacao(async (consultar) => {
      await consultar(
        'UPDATE operador SET status = $3 WHERE organizacao_id = $1 AND id = $2',
        [usuario.organizacaoId, id, status],
      );
      await registrarAuditoria(consultar, usuario, {
        acao:
          status === 'ATIVO' ? 'REATIVACAO_OPERADOR' : 'DESATIVACAO_OPERADOR',
        entidade: 'operador',
        entidadeId: id,
        descricao:
          status === 'ATIVO'
            ? `Acesso do operador ${atual.nome} reativado.`
            : `Acesso do operador ${atual.nome} desativado.`,
      });
    });
    return this.buscar(usuario.organizacaoId, id);
  }

  // O operador esqueceu a senha: o administrador gera outra provisória. A
  // antiga deixa de funcionar e as sessões abertas caem.
  async novaSenha(usuario: UsuarioLogado, id: string) {
    const operador = await this.buscar(usuario.organizacaoId, id);
    const senhaProvisoria = gerarSenha();
    await this.banco.transacao(async (consultar) => {
      await definirSenha(consultar, 'operador', id, senhaProvisoria, {
        provisoria: true,
      });
      await registrarAuditoria(consultar, usuario, {
        acao: 'NOVA_SENHA_OPERADOR',
        entidade: 'operador',
        entidadeId: id,
        descricao: `Nova senha provisória gerada para o operador ${operador.nome}.`,
      });
    });
    const emailEnviado = await this.enviarSenha(
      usuario.organizacaoId,
      operador,
      senhaProvisoria,
    );
    return { senhaProvisoria, emailEnviado };
  }

  private async enviarSenha(
    organizacaoId: string,
    operador: { nome: string; email: string },
    senha: string,
  ) {
    const [org] = await this.banco.consultar<{ nome: string }>(
      'SELECT nome FROM organizacao WHERE id = $1',
      [organizacaoId],
    );
    return this.email.enviarSenhaProvisoria({
      para: operador.email,
      nome: operador.nome,
      organizacao: org.nome,
      senha,
      papel: 'operador',
    });
  }
}

function paraOperador(l: LinhaOperador) {
  return {
    id: l.id,
    nome: l.nome,
    email: l.email,
    telefone: l.telefone,
    status: l.status,
    foto: l.foto ? l.foto.toString('base64') : null,
    fotoTipo: l.foto_tipo,
    checkinsHoje: l.checkins_hoje,
    ultimoCheckin: l.ultimo_checkin,
  };
}
