import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BancoService } from '../banco/banco.service';
import { Datas } from '../comum/datas';
import { SalvarFotoDto } from './dto/salvar-foto.dto';
import { QrCarteirinha } from './qr-carteirinha';

const TAMANHO_MAXIMO_FOTO = 512 * 1024;

interface LinhaCarteirinha {
  membro_nome: string;
  membro_email: string;
  data_adesao: string;
  foto: Buffer | null;
  foto_tipo: string | null;
  plano_id: string;
  plano_nome: string;
  plano_cor: string | null;
  carteirinha_id: string;
  status: 'ATIVA' | 'BLOQUEADA' | 'INVALIDADA';
  data_emissao: string;
  data_vencimento: string;
  qr_versao: number;
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
  logo: Buffer | null;
  logo_tipo: string | null;
}

interface LinhaLocal {
  id: string;
  nome: string;
  tipo: 'UNIDADE' | 'EVENTO';
  localizacao: string | null;
  data_inicio: string | null;
  data_fim: string | null;
  imagem: Buffer | null;
  imagem_tipo: string | null;
}

// RF05 e RF09: o que o membro logado vê no app. Sempre a partir do id do
// token, nunca de um parâmetro: o membro só enxerga os próprios dados.
@Injectable()
export class AreaMembroService {
  constructor(
    private readonly banco: BancoService,
    private readonly qr: QrCarteirinha,
  ) {}

  async carteirinha(membroId: string, organizacaoId: string) {
    const [l] = await this.banco.consultar<LinhaCarteirinha>(
      `SELECT m.nome AS membro_nome, m.email AS membro_email, m.data_adesao, m.foto, m.foto_tipo,
              p.id AS plano_id, p.nome AS plano_nome, p.cor AS plano_cor,
              c.id AS carteirinha_id, c.status, c.data_emissao, c.data_vencimento, c.qr_versao
       FROM membro m
       JOIN plano_associacao p ON p.id = m.plano_id
       JOIN carteirinha c ON c.membro_id = m.id
       WHERE m.id = $1 AND m.organizacao_id = $2 AND m.status = 'ATIVO'`,
      [membroId, organizacaoId],
    );
    if (!l) throw new NotFoundException('Carteirinha não encontrada.');

    // O sistema nunca bloqueia sozinho: vencida, mas ativa, ainda tem QR.
    // Só a administração bloqueia ou invalida, e aí o QR deixa de existir.
    const qr =
      l.status === 'ATIVA'
        ? await this.qr.gerar({
            c: l.carteirinha_id,
            v: l.qr_versao,
            o: organizacaoId,
          })
        : null;

    return {
      membro: {
        nome: l.membro_nome,
        email: l.membro_email,
        dataAdesao: l.data_adesao,
        foto: l.foto ? l.foto.toString('base64') : null,
        fotoTipo: l.foto_tipo,
      },
      plano: { id: l.plano_id, nome: l.plano_nome, cor: l.plano_cor },
      carteirinha: {
        // Número curto para conferência visual, derivado do id.
        numero: l.carteirinha_id.replace(/-/g, '').slice(0, 8).toUpperCase(),
        status: l.status,
        dataEmissao: l.data_emissao,
        dataVencimento: l.data_vencimento,
      },
      qr,
    };
  }

  // A foto é do próprio membro: só ele troca, pela área dele no app.
  async salvarFoto(
    membroId: string,
    organizacaoId: string,
    dados: SalvarFotoDto,
  ) {
    const foto = dados.foto ? Buffer.from(dados.foto, 'base64') : null;
    if (foto && foto.length > TAMANHO_MAXIMO_FOTO) {
      throw new BadRequestException('A foto pode ter no máximo 512 KB.');
    }
    const linhas = await this.banco.consultar<{ id: string }>(
      `UPDATE membro SET foto = $3, foto_tipo = $4
       WHERE id = $1 AND organizacao_id = $2 AND status = 'ATIVO'
       RETURNING id`,
      [membroId, organizacaoId, foto, foto ? dados.fotoTipo : null],
    );
    if (linhas.length === 0)
      throw new NotFoundException('Membro não encontrado.');
    return this.carteirinha(membroId, organizacaoId);
  }

  // Benefícios do plano do membro que estão vigentes hoje.
  async beneficios(membroId: string, organizacaoId: string) {
    const linhas = await this.banco.consultar<LinhaBeneficio>(
      `SELECT b.id, b.nome, b.descricao, b.parceiro, b.tipo_desconto, b.valor_desconto,
              b.vig_inicio, b.vig_fim, b.logo, b.logo_tipo
       FROM membro m
       JOIN plano_beneficio pb ON pb.plano_id = m.plano_id
       JOIN beneficio b ON b.id = pb.beneficio_id AND b.organizacao_id = m.organizacao_id
       WHERE m.id = $1 AND m.organizacao_id = $2
         AND (b.vig_inicio IS NULL OR b.vig_inicio <= $3)
         AND (b.vig_fim IS NULL OR b.vig_fim >= $3)
       ORDER BY b.nome`,
      [membroId, organizacaoId, Datas.hoje()],
    );
    return linhas.map((b) => ({
      id: b.id,
      nome: b.nome,
      descricao: b.descricao,
      parceiro: b.parceiro,
      tipoDesconto: b.tipo_desconto,
      valorDesconto: Number(b.valor_desconto),
      vigInicio: b.vig_inicio,
      vigFim: b.vig_fim,
      logo: b.logo ? b.logo.toString('base64') : null,
      logoTipo: b.logo_tipo,
    }));
  }

  // Unidades e eventos (que ainda não acabaram) onde o plano é aceito.
  async locais(membroId: string, organizacaoId: string) {
    const linhas = await this.banco.consultar<LinhaLocal>(
      `SELECT u.id, u.nome, u.tipo, u.localizacao, u.data_inicio, u.data_fim, u.imagem, u.imagem_tipo
       FROM membro m
       JOIN unidade_evento_plano up ON up.plano_id = m.plano_id
       JOIN unidade_evento u ON u.id = up.unidade_evento_id AND u.organizacao_id = m.organizacao_id
       WHERE m.id = $1 AND m.organizacao_id = $2
         AND (u.data_fim IS NULL OR u.data_fim >= $3)
       ORDER BY u.tipo DESC, u.data_inicio NULLS FIRST, u.nome`,
      [membroId, organizacaoId, Datas.hoje()],
    );
    return linhas.map((u) => ({
      id: u.id,
      nome: u.nome,
      tipo: u.tipo,
      localizacao: u.localizacao,
      dataInicio: u.data_inicio,
      dataFim: u.data_fim,
      imagem: u.imagem ? u.imagem.toString('base64') : null,
      imagemTipo: u.imagem_tipo,
    }));
  }
}
