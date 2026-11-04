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
const ESTILOS_FUNDO = ['DEGRADE', 'SOLIDO', 'PADRAO'] as const;
const MODELOS = ['CLASSICO', 'MODERNO', 'MINIMALISTA'] as const;

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

  // Segunda cor do degradê; null deixa automática (versão escura da principal).
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @IsOptional()
  @ValidateIf((_, valor) => valor !== null)
  @Matches(/^#[0-9A-F]{6}$/, {
    message: 'Segunda cor inválida. Use o formato #RRGGBB.',
  })
  corSecundaria?: string | null;

  @IsIn(ESTILOS_FUNDO, { message: 'Estilo de fundo inválido.' })
  estiloFundo!: (typeof ESTILOS_FUNDO)[number];

  @IsIn(MODELOS, { message: 'Modelo de carteirinha inválido.' })
  modeloCarteirinha!: (typeof MODELOS)[number];

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
  cor_secundaria: string | null;
  estilo_fundo: string;
  modelo_carteirinha: string;
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
    if (
      dados.corSecundaria &&
      contrasteComBranco(dados.corSecundaria) < CONTRASTE_MINIMO
    ) {
      throw new BadRequestException(
        'A segunda cor é clara demais: o texto branco da carteirinha ficaria ilegível.',
      );
    }

    const logo =
      typeof dados.logo === 'string' ? Buffer.from(dados.logo, 'base64') : null;
    if (logo && logo.length > TAMANHO_MAXIMO_LOGO) {
      throw new BadRequestException('O logo pode ter no máximo 512 KB.');
    }

    await this.banco.transacao(async (consultar) => {
      await consultar(
        `UPDATE organizacao
         SET cor_principal = $2, cor_secundaria = $3, estilo_fundo = $4, modelo_carteirinha = $5
         WHERE id = $1`,
        [
          usuario.organizacaoId,
          dados.corPrincipal,
          dados.corSecundaria ?? null,
          dados.estiloFundo,
          dados.modeloCarteirinha,
        ],
      );
      // Logo ausente na requisição: mantém o atual.
      if (dados.logo !== undefined) {
        await consultar(
          'UPDATE organizacao SET logo = $2, logo_tipo = $3 WHERE id = $1',
          [usuario.organizacaoId, logo, logo ? dados.logoTipo : null],
        );
      }
    });
    return this.buscarOrganizacao(usuario.organizacaoId);
  }

  private async buscarOrganizacao(id: string) {
    const [org] = await this.banco.consultar<LinhaOrganizacao>(
      `SELECT id, nome, status, cor_principal, cor_secundaria, estilo_fundo,
              modelo_carteirinha, logo, logo_tipo
       FROM organizacao WHERE id = $1`,
      [id],
    );
    if (!org) throw new NotFoundException('Organização não encontrada.');
    return {
      id: org.id,
      nome: org.nome,
      status: org.status,
      corPrincipal: org.cor_principal,
      corSecundaria: org.cor_secundaria,
      estiloFundo: org.estilo_fundo,
      modeloCarteirinha: org.modelo_carteirinha,
      logo: org.logo ? org.logo.toString('base64') : null,
      logoTipo: org.logo_tipo,
    };
  }
}
