import { Transform } from 'class-transformer';
import {
  IsArray,
  IsDateString,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class SalvarUnidadeEventoDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @IsNotEmpty({ message: 'Informe o nome.' })
  @MaxLength(150, { message: 'O nome pode ter no máximo 150 caracteres.' })
  nome!: string;

  @IsIn(['UNIDADE', 'EVENTO'], { message: 'Escolha unidade ou evento.' })
  tipo!: 'UNIDADE' | 'EVENTO';

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() || null : value,
  )
  @IsOptional()
  @IsString()
  @MaxLength(255, {
    message: 'A localização pode ter no máximo 255 caracteres.',
  })
  localizacao?: string | null;

  // Obrigatórias para evento; ignoradas para unidade.
  @IsOptional()
  @IsDateString({ strict: true }, { message: 'Data de início inválida.' })
  dataInicio?: string | null;

  @IsOptional()
  @IsDateString({ strict: true }, { message: 'Data de fim inválida.' })
  dataFim?: string | null;

  @IsArray()
  @IsUUID('all', { each: true, message: 'Plano inválido.' })
  planoIds!: string[];
}
