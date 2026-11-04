import { Transform } from 'class-transformer';
import {
  IsBase64,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

const aparar = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

// Texto opcional: tira espaços e transforma vazio em null.
const opcional = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() || null : value;

export class SalvarPerfilDto {
  @Transform(aparar)
  @IsString()
  @IsNotEmpty({ message: 'Informe seu nome.' })
  @MaxLength(150, { message: 'O nome pode ter no máximo 150 caracteres.' })
  nome!: string;

  @Transform(opcional)
  @IsOptional()
  @Matches(/^[\d\s()+-]{8,20}$/, { message: 'Informe um telefone válido.' })
  telefone?: string | null;

  @Transform(opcional)
  @IsOptional()
  @IsString()
  @MaxLength(80, { message: 'O cargo pode ter no máximo 80 caracteres.' })
  cargo?: string | null;

  // Ausente: mantém a foto atual. null: remove. Texto: nova foto em base64.
  @IsOptional()
  @ValidateIf((_, valor) => valor !== null)
  @IsBase64({}, { message: 'Foto inválida.' })
  foto?: string | null;

  @ValidateIf((dados: SalvarPerfilDto) => typeof dados.foto === 'string')
  @IsIn(['image/png', 'image/jpeg'], {
    message: 'A foto deve ser PNG ou JPEG.',
  })
  fotoTipo?: string;
}

export class TrocarSenhaDto {
  @IsString()
  @IsNotEmpty({ message: 'Informe sua senha atual.' })
  senhaAtual!: string;

  // Mínimo de 8 caracteres, com pelo menos uma letra e um número.
  @IsString()
  @MinLength(8, {
    message: 'A nova senha precisa ter pelo menos 8 caracteres.',
  })
  @MaxLength(72, { message: 'A nova senha pode ter no máximo 72 caracteres.' })
  @Matches(/(?=.*[A-Za-z])(?=.*\d)/, {
    message: 'A nova senha precisa ter letras e números.',
  })
  novaSenha!: string;
}
