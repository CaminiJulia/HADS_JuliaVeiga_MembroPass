import { Transform } from 'class-transformer';
import {
  IsArray,
  IsDateString,
  IsIn,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

// Texto opcional: tira espaços e transforma vazio em null.
const aparar = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() || null : value;

export class SalvarBeneficioDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @IsNotEmpty({ message: 'Informe o nome do benefício.' })
  @MaxLength(100, { message: 'O nome pode ter no máximo 100 caracteres.' })
  nome!: string;

  @Transform(aparar)
  @IsOptional()
  @IsString()
  @MaxLength(1000, {
    message: 'A descrição pode ter no máximo 1000 caracteres.',
  })
  descricao?: string | null;

  @Transform(aparar)
  @IsOptional()
  @IsString()
  @MaxLength(150, { message: 'O parceiro pode ter no máximo 150 caracteres.' })
  parceiro?: string | null;

  @IsIn(['PERCENTUAL', 'VALOR'], { message: 'Tipo de desconto inválido.' })
  tipoDesconto!: 'PERCENTUAL' | 'VALOR';

  @IsNumber(
    { maxDecimalPlaces: 2 },
    { message: 'Informe o desconto com no máximo 2 casas decimais.' },
  )
  @Min(0.01, { message: 'O desconto deve ser maior que zero.' })
  @Max(99_999_999.99, { message: 'Desconto muito alto.' })
  valorDesconto!: number;

  @IsOptional()
  @IsDateString({ strict: true }, { message: 'Data de início inválida.' })
  vigInicio?: string | null;

  @IsOptional()
  @IsDateString({ strict: true }, { message: 'Data de fim inválida.' })
  vigFim?: string | null;

  @IsArray()
  @IsUUID('all', { each: true, message: 'Plano inválido.' })
  planoIds!: string[];
}
