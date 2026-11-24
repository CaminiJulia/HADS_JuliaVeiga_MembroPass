import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BancoService } from '../banco/banco.service';
import { SalvarPerfilDto } from './dto/perfil.dto';

const TAMANHO_MAXIMO_FOTO = 512 * 1024;

// Papéis com a aba "Meu perfil". O membro tem a própria área (area-membro).
export type PapelComPerfil = 'administrador' | 'operador';

// Tabela de cada papel. O nome vai direto no SQL, então só sai desta lista
// fixa, nunca da requisição. O operador não tem cargo: o papel já diz a função.
const CADASTRO: Record<PapelComPerfil, { tabela: string; temCargo: boolean }> =
  {
    administrador: { tabela: 'administrador', temCargo: true },
    operador: { tabela: 'operador', temCargo: false },
  };

interface LinhaPerfil {
  id: string;
  nome: string;
  email: string;
  telefone: string | null;
  cargo: string | null;
  foto: Buffer | null;
  foto_tipo: string | null;
  organizacao_nome: string;
}

// Perfil de quem está logado: só a própria conta, nunca a de outro.
@Injectable()
export class PerfilService {
  constructor(private readonly banco: BancoService) {}

  async buscar(papel: PapelComPerfil, id: string) {
    const { tabela, temCargo } = CADASTRO[papel];
    const [linha] = await this.banco.consultar<LinhaPerfil>(
      `SELECT u.id, u.nome, u.email, u.telefone, ${temCargo ? 'u.cargo' : 'NULL'} AS cargo,
              u.foto, u.foto_tipo, o.nome AS organizacao_nome
       FROM ${tabela} u
       JOIN organizacao o ON o.id = u.organizacao_id
       WHERE u.id = $1 AND u.status = 'ATIVO'`,
      [id],
    );
    if (!linha) throw new NotFoundException('Conta não encontrada.');
    return {
      id: linha.id,
      papel,
      nome: linha.nome,
      email: linha.email,
      telefone: linha.telefone,
      cargo: linha.cargo,
      foto: linha.foto ? linha.foto.toString('base64') : null,
      fotoTipo: linha.foto_tipo,
      organizacaoNome: linha.organizacao_nome,
    };
  }

  async salvar(papel: PapelComPerfil, id: string, dados: SalvarPerfilDto) {
    const { tabela, temCargo } = CADASTRO[papel];
    const foto =
      typeof dados.foto === 'string' ? Buffer.from(dados.foto, 'base64') : null;
    if (foto && foto.length > TAMANHO_MAXIMO_FOTO) {
      throw new BadRequestException('A foto pode ter no máximo 512 KB.');
    }

    await this.banco.transacao(async (consultar) => {
      await (temCargo
        ? consultar(
            `UPDATE ${tabela} SET nome = $2, telefone = $3, cargo = $4 WHERE id = $1`,
            [id, dados.nome, dados.telefone ?? null, dados.cargo ?? null],
          )
        : consultar(
            `UPDATE ${tabela} SET nome = $2, telefone = $3 WHERE id = $1`,
            [id, dados.nome, dados.telefone ?? null],
          ));
      // Foto ausente na requisição: mantém a atual.
      if (dados.foto !== undefined) {
        await consultar(
          `UPDATE ${tabela} SET foto = $2, foto_tipo = $3 WHERE id = $1`,
          [id, foto, foto ? dados.fotoTipo : null],
        );
      }
    });
    return this.buscar(papel, id);
  }
}
