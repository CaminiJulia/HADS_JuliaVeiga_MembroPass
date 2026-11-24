import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

const aparar = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

// Texto opcional: tira espaços e transforma vazio em null.
const opcional = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() || null : value;

export class SalvarOperadorDto {
  @Transform(aparar)
  @IsString()
  @IsNotEmpty({ message: 'Informe o nome do operador.' })
  @MaxLength(150, { message: 'O nome pode ter no máximo 150 caracteres.' })
  nome!: string;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'Informe um e-mail válido.' })
  @MaxLength(255)
  email!: string;

  @Transform(opcional)
  @IsOptional()
  @Matches(/^[\d\s()+-]{8,20}$/, { message: 'Informe um telefone válido.' })
  telefone?: string | null;
}

export class AlterarStatusOperadorDto {
  @IsIn(['ATIVO', 'INATIVO'], { message: 'Status inválido.' })
  status!: 'ATIVO' | 'INATIVO';
}
