import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import {
  numeroCarteirinha,
  QrCarteirinha,
} from '../area-membro/qr-carteirinha';
import { BancoService } from '../banco/banco.service';
import { Datas } from '../comum/datas';
import { RegistrarCheckinDto } from './dto/registrar-checkin.dto';
import {
  avaliarCheckin,
  MENSAGEM_RECUSA,
  MotivoRecusa,
} from './regras-checkin';

interface LinhaLocal {
  id: string;
  nome: string;
  tipo: 'UNIDADE' | 'EVENTO';
  localizacao: string | null;
  data_inicio: string | null;
  data_fim: string | null;
}

interface LinhaCarteirinha {
  carteirinha_id: string;
  qr_versao: number;
  status: 'ATIVA' | 'BLOQUEADA' | 'INVALIDADA';
  data_vencimento: string;
  membro_id: string;
  membro_nome: string;
  membro_status: 'ATIVO' | 'DESATIVADO' | 'CANCELADO';
  foto: Buffer | null;
  foto_tipo: string | null;
  plano_nome: string;
  plano_cor: string | null;
  plano_aceito: boolean;
}

type Forma = 'QR' | 'NUMERO';

interface LinhaCheckin {
  id: string;
  data_hora: Date;
  aprovado: boolean;
  motivo_recusa: MotivoRecusa | null;
  vencida: boolean;
  forma: Forma;
  membro_nome: string | null;
  plano_nome: string | null;
  plano_cor: string | null;
}

// A carteirinha e se o plano do membro é aceito no local ($2). Quem usa
// completa o WHERE: pelo id (QR Code) ou pelo número digitado.
const SQL_CARTEIRINHA = `
  SELECT c.id AS carteirinha_id, c.qr_versao, c.status, c.data_vencimento,
         m.id AS membro_id, m.nome AS membro_nome, m.status AS membro_status,
         m.foto, m.foto_tipo, p.nome AS plano_nome, p.cor AS plano_cor,
         EXISTS (
           SELECT 1 FROM unidade_evento_plano up
           WHERE up.unidade_evento_id = $2 AND up.plano_id = m.plano_id
         ) AS plano_aceito
  FROM carteirinha c
  JOIN membro m ON m.id = c.membro_id
  JOIN plano_associacao p ON p.id = m.plano_id
  WHERE m.organizacao_id = $1
`;

// Unidades sempre; eventos só nos dias do período.
const SQL_LOCAIS_DE_HOJE = `
  SELECT id, nome, tipo, localizacao, data_inicio, data_fim
  FROM unidade_evento
  WHERE organizacao_id = $1
    AND (tipo = 'UNIDADE' OR (data_inicio <= $2 AND data_fim >= $2))
`;

// RF10: o operador lê o QR Code da carteirinha num local e o sistema aprova
// ou recusa. Toda leitura fica registrada, com o motivo da recusa.
@Injectable()
export class OperadorService {
  constructor(
    private readonly banco: BancoService,
    private readonly qr: QrCarteirinha,
  ) {}

  // Onde o operador pode fazer check-in hoje.
  async locais(organizacaoId: string) {
    const linhas = await this.banco.consultar<LinhaLocal>(
      `${SQL_LOCAIS_DE_HOJE} ORDER BY tipo DESC, nome`,
      [organizacaoId, Datas.hoje()],
    );
    return linhas.map((l) => ({
      id: l.id,
      nome: l.nome,
      tipo: l.tipo,
      localizacao: l.localizacao,
      dataInicio: l.data_inicio,
      dataFim: l.data_fim,
    }));
  }

  async registrar(
    operadorId: string,
    organizacaoId: string,
    dados: RegistrarCheckinDto,
  ) {
    const hoje = Datas.hoje();
    const local = await this.localDeHoje(
      organizacaoId,
      dados.unidadeEventoId,
      hoje,
    );

    if (dados.codigo !== undefined && dados.numero !== undefined) {
      throw new BadRequestException(
        'Envie o QR Code ou o número, não os dois.',
      );
    }
    const forma: Forma = dados.numero !== undefined ? 'NUMERO' : 'QR';
    const lida =
      forma === 'QR'
        ? await this.porQr(organizacaoId, local.id, dados.codigo!)
        : await this.porNumero(organizacaoId, local.id, dados.numero!);

    if (!lida) {
      const motivo = forma === 'QR' ? 'QR_INVALIDO' : 'NUMERO_INVALIDO';
      const registro = await this.gravar({
        organizacaoId,
        operadorId,
        local,
        membroId: null,
        motivo,
        vencida: false,
        forma,
      });
      return {
        ...registro,
        aprovado: false,
        motivo,
        mensagem: MENSAGEM_RECUSA[motivo],
        vencida: false,
        forma,
        entradaAnteriorHoje: null,
        membro: null,
      };
    }
    const { carteirinha: c, versaoLida, qrExpirado } = lida;

    const { motivo, vencida } = avaliarCheckin(
      {
        membroAtivo: c.membro_status === 'ATIVO',
        status: c.status,
        versaoAtual: c.qr_versao,
        versaoLida,
        qrExpirado,
        planoAceito: c.plano_aceito,
        dataVencimento: c.data_vencimento,
      },
      hoje,
    );

    // Uma carteirinha passando duas vezes no mesmo dia merece atenção do
    // operador (pode estar sendo emprestada), mas não é recusada.
    const [anterior] = motivo
      ? []
      : await this.banco.consultar<{ data_hora: Date }>(
          `SELECT data_hora FROM checkin
           WHERE organizacao_id = $1 AND unidade_evento_id = $2 AND membro_id = $3
             AND aprovado AND data_hora >= $4::date
           ORDER BY data_hora DESC LIMIT 1`,
          [organizacaoId, local.id, c.membro_id, hoje],
        );

    const registro = await this.gravar({
      organizacaoId,
      operadorId,
      local,
      membroId: c.membro_id,
      motivo,
      vencida,
      forma,
    });

    return {
      ...registro,
      aprovado: motivo === null,
      motivo,
      mensagem: motivo ? MENSAGEM_RECUSA[motivo] : null,
      vencida,
      forma,
      entradaAnteriorHoje: anterior?.data_hora ?? null,
      membro: {
        nome: c.membro_nome,
        foto: c.foto ? c.foto.toString('base64') : null,
        fotoTipo: c.foto_tipo,
        numero: numeroCarteirinha(c.carteirinha_id),
        planoNome: c.plano_nome,
        planoCor: c.plano_cor,
        dataVencimento: c.data_vencimento,
      },
    };
  }

  // Leituras de hoje no local, as mais recentes primeiro.
  async checkinsDeHoje(organizacaoId: string, unidadeEventoId: string) {
    const linhas = await this.banco.consultar<LinhaCheckin>(
      `SELECT ck.id, ck.data_hora, ck.aprovado, ck.motivo_recusa, ck.vencida, ck.forma,
              m.nome AS membro_nome, p.nome AS plano_nome, p.cor AS plano_cor
       FROM checkin ck
       LEFT JOIN membro m ON m.id = ck.membro_id
       LEFT JOIN plano_associacao p ON p.id = m.plano_id
       WHERE ck.organizacao_id = $1 AND ck.unidade_evento_id = $2
         AND ck.data_hora >= $3::date
       ORDER BY ck.data_hora DESC
       LIMIT 200`,
      [organizacaoId, unidadeEventoId, Datas.hoje()],
    );
    return linhas.map((l) => ({
      id: l.id,
      dataHora: l.data_hora,
      aprovado: l.aprovado,
      motivo: l.motivo_recusa,
      mensagem: l.motivo_recusa ? MENSAGEM_RECUSA[l.motivo_recusa] : null,
      vencida: l.vencida,
      forma: l.forma,
      membroNome: l.membro_nome,
      planoNome: l.plano_nome,
      planoCor: l.plano_cor,
    }));
  }

  // Assinatura válida; senão, nem procura o membro. A carteirinha precisa ser
  // da organização do operador. Expirado (captura de tela) ainda identifica
  // o membro: a recusa fica registrada no nome dele.
  private async porQr(organizacaoId: string, localId: string, codigo: string) {
    const lido = this.qr.ler(codigo);
    if (!lido.ok && lido.motivo === 'invalido') return null;
    const { carteirinhaId, versao } = lido;
    const [carteirinha] = await this.banco.consultar<LinhaCarteirinha>(
      `${SQL_CARTEIRINHA} AND c.id = $3`,
      [organizacaoId, localId, carteirinhaId],
    );
    return carteirinha
      ? { carteirinha, versaoLida: versao, qrExpirado: !lido.ok }
      : null;
  }

  // O número são os 8 primeiros caracteres do id (numeroCarteirinha). Não
  // tem versão como o QR: quem garante é o operador, conferindo a foto.
  private async porNumero(
    organizacaoId: string,
    localId: string,
    numero: string,
  ) {
    const linhas = await this.banco.consultar<LinhaCarteirinha>(
      `${SQL_CARTEIRINHA} AND left(c.id::text, 8) = lower($3) LIMIT 2`,
      [organizacaoId, localId, numero],
    );
    if (linhas.length > 1) {
      throw new UnprocessableEntityException(
        'Mais de uma carteirinha com este número. Use o QR Code.',
      );
    }
    const [carteirinha] = linhas;
    return carteirinha
      ? { carteirinha, versaoLida: carteirinha.qr_versao, qrExpirado: false }
      : null;
  }

  private async localDeHoje(organizacaoId: string, id: string, hoje: string) {
    const [local] = await this.banco.consultar<LinhaLocal>(
      'SELECT id, nome, tipo, data_inicio, data_fim FROM unidade_evento WHERE organizacao_id = $1 AND id = $2',
      [organizacaoId, id],
    );
    // 404 e 409 avisam o app que o local escolhido deixou de valer.
    if (!local) throw new NotFoundException('Local não encontrado.');
    if (
      local.tipo === 'EVENTO' &&
      (local.data_inicio! > hoje || local.data_fim! < hoje)
    ) {
      throw new ConflictException(
        'Este evento não está acontecendo hoje. Escolha outro local.',
      );
    }
    return local;
  }

  private async gravar(d: {
    organizacaoId: string;
    operadorId: string;
    local: LinhaLocal;
    membroId: string | null;
    motivo: MotivoRecusa | null;
    vencida: boolean;
    forma: Forma;
  }) {
    const [registro] = await this.banco.consultar<{
      id: string;
      data_hora: Date;
    }>(
      `INSERT INTO checkin (organizacao_id, operador_id, unidade_evento_id, local_nome,
                            membro_id, aprovado, motivo_recusa, vencida, forma)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, data_hora`,
      [
        d.organizacaoId,
        d.operadorId,
        d.local.id,
        d.local.nome,
        d.membroId,
        d.motivo === null,
        d.motivo,
        d.vencida,
        d.forma,
      ],
    );
    return { id: registro.id, dataHora: registro.data_hora };
  }
}
