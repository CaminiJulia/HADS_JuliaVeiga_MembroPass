import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { BancoService } from '../banco/banco.service';
import { SalvarPerfilDto, TrocarSenhaDto } from './dto/perfil.dto';

const TAMANHO_MAXIMO_FOTO = 512 * 1024;

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

// Perfil do administrador logado: só a própria conta, nunca a de outro.
@Injectable()
export class PerfilService {
  constructor(private readonly banco: BancoService) {}

  async buscar(id: string) {
    const [linha] = await this.banco.consultar<LinhaPerfil>(
      `SELECT a.id, a.nome, a.email, a.telefone, a.cargo, a.foto, a.foto_tipo,
              o.nome AS organizacao_nome
       FROM administrador a
       JOIN organizacao o ON o.id = a.organizacao_id
       WHERE a.id = $1 AND a.status = 'ATIVO'`,
      [id],
    );
    if (!linha) throw new NotFoundException('Conta não encontrada.');
    return {
      id: linha.id,
      nome: linha.nome,
      email: linha.email,
      telefone: linha.telefone,
      cargo: linha.cargo,
      foto: linha.foto ? linha.foto.toString('base64') : null,
      fotoTipo: linha.foto_tipo,
      organizacaoNome: linha.organizacao_nome,
    };
  }

  async salvar(id: string, dados: SalvarPerfilDto) {
    const foto =
      typeof dados.foto === 'string' ? Buffer.from(dados.foto, 'base64') : null;
    if (foto && foto.length > TAMANHO_MAXIMO_FOTO) {
      throw new BadRequestException('A foto pode ter no máximo 512 KB.');
    }

    await this.banco.transacao(async (consultar) => {
      await consultar(
        'UPDATE administrador SET nome = $2, telefone = $3, cargo = $4 WHERE id = $1',
        [id, dados.nome, dados.telefone ?? null, dados.cargo ?? null],
      );
      // Foto ausente na requisição: mantém a atual.
      if (dados.foto !== undefined) {
        await consultar(
          'UPDATE administrador SET foto = $2, foto_tipo = $3 WHERE id = $1',
          [id, foto, foto ? dados.fotoTipo : null],
        );
      }
    });
    return this.buscar(id);
  }

  async trocarSenha(id: string, dados: TrocarSenhaDto) {
    const [conta] = await this.banco.consultar<{ senha_hash: string }>(
      `SELECT senha_hash FROM administrador WHERE id = $1 AND status = 'ATIVO'`,
      [id],
    );
    if (!conta) throw new NotFoundException('Conta não encontrada.');
    if (!(await bcrypt.compare(dados.senhaAtual, conta.senha_hash))) {
      throw new BadRequestException('A senha atual está incorreta.');
    }
    if (dados.senhaAtual === dados.novaSenha) {
      throw new BadRequestException(
        'A nova senha precisa ser diferente da atual.',
      );
    }
    const hash = await bcrypt.hash(dados.novaSenha, 10);
    await this.banco.consultar(
      'UPDATE administrador SET senha_hash = $2 WHERE id = $1',
      [id, hash],
    );
  }
}
