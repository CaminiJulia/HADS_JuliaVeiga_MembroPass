import {
  BadRequestException,
  Body,
  Controller,
  Get,
  NotFoundException,
  Put,
} from '@nestjs/common';
import { Transform } from 'class-transformer';
import {
  IsBase64,
  IsIn,
  IsOptional,
  Matches,
  ValidateIf,
} from 'class-validator';
import { Apenas, Usuario } from '../auth/autenticacao.guard';
import type { UsuarioLogado } from '../auth/autenticacao.guard';
import { BancoService } from '../banco/banco.service';
import { CONTRASTE_MINIMO, contrasteComBranco } from './contraste';

const TAMANHO_MAXIMO_LOGO = 512 * 1024;

export class SalvarIdentidadeDto {
  // null volta para a cor padrão da plataforma.
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @ValidateIf((_, valor) => valor !== null)
  @Matches(/^#[0-9A-F]{6}$/, {
    message: 'Cor inválida. Use o formato #RRGGBB.',
  })
  corPrincipal!: string | null;

  // Ausente: mantém o logo atual. null: remove. Texto: novo logo em base64.
  @IsOptional()
  @ValidateIf((_, valor) => valor !== null)
  @IsBase64({}, { message: 'Logo inválido.' })
  logo?: string | null;

  @ValidateIf((dados: SalvarIdentidadeDto) => typeof dados.logo === 'string')
  @IsIn(['image/png', 'image/jpeg'], {
    message: 'O logo deve ser PNG ou JPEG.',
  })
  logoTipo?: string;
}

interface LinhaOrganizacao {
  id: string;
  nome: string;
  status: string;
  cor_principal: string | null;
  logo: Buffer | null;
  logo_tipo: string | null;
}

// RF03 e RF17: dados e identidade visual da organização de quem está logado.
// Membros e operadores também leem, porque a carteirinha usa a marca.
@Controller('organizacao')
export class OrganizacaoController {
  constructor(private readonly banco: BancoService) {}

  @Get()
  @Apenas('administrador', 'operador', 'membro')
  buscar(@Usuario() usuario: UsuarioLogado) {
    return this.buscarOrganizacao(usuario.organizacaoId);
  }

  @Put('identidade')
  @Apenas('administrador')
  async salvarIdentidade(
    @Usuario() usuario: UsuarioLogado,
    @Body() dados: SalvarIdentidadeDto,
  ) {
    if (
      dados.corPrincipal &&
      contrasteComBranco(dados.corPrincipal) < CONTRASTE_MINIMO
    ) {
      throw new BadRequestException(
        'Essa cor é clara demais: o texto branco da carteirinha ficaria ilegível.',
      );
    }

    const logo =
      typeof dados.logo === 'string' ? Buffer.from(dados.logo, 'base64') : null;
    if (logo && logo.length > TAMANHO_MAXIMO_LOGO) {
      throw new BadRequestException('O logo pode ter no máximo 512 KB.');
    }

    if (dados.logo === undefined) {
      await this.banco.consultar(
        'UPDATE organizacao SET cor_principal = $2 WHERE id = $1',
        [usuario.organizacaoId, dados.corPrincipal],
      );
    } else {
      await this.banco.consultar(
        `UPDATE organizacao SET cor_principal = $2, logo = $3, logo_tipo = $4
         WHERE id = $1`,
        [
          usuario.organizacaoId,
          dados.corPrincipal,
          logo,
          logo ? dados.logoTipo : null,
        ],
      );
    }
    return this.buscarOrganizacao(usuario.organizacaoId);
  }

  private async buscarOrganizacao(id: string) {
    const [org] = await this.banco.consultar<LinhaOrganizacao>(
      `SELECT id, nome, status, cor_principal, logo, logo_tipo
       FROM organizacao WHERE id = $1`,
      [id],
    );
    if (!org) throw new NotFoundException('Organização não encontrada.');
    return {
      id: org.id,
      nome: org.nome,
      status: org.status,
      corPrincipal: org.cor_principal,
      logo: org.logo ? org.logo.toString('base64') : null,
      logoTipo: org.logo_tipo,
    };
  }
}
