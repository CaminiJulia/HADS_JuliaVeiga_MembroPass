import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
} from 'class-validator';

const aparar = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

export class SalvarMembroDto {
  @Transform(aparar)
  @IsString()
  @IsNotEmpty({ message: 'Informe o nome do membro.' })
  @MaxLength(150, { message: 'O nome pode ter no máximo 150 caracteres.' })
  nome!: string;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'Informe um e-mail válido.' })
  @MaxLength(255)
  email!: string;

  // Telefone opcional; vazio vira null.
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() || null : value,
  )
  @IsOptional()
  @Matches(/^[\d\s()+-]{8,20}$/, { message: 'Informe um telefone válido.' })
  telefone?: string | null;

  @IsUUID('all', { message: 'Escolha um plano.' })
  planoId!: string;
}

export class AlterarStatusMembroDto {
  @IsIn(['ATIVO', 'DESATIVADO'], { message: 'Status inválido.' })
  status!: 'ATIVO' | 'DESATIVADO';
}

export class BuscarMembrosDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  busca?: string;
}
