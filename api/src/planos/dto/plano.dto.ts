import { Transform } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class SalvarPlanoDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @IsNotEmpty({ message: 'Informe o nome do plano.' })
  @MaxLength(100, { message: 'O nome pode ter no máximo 100 caracteres.' })
  nome!: string;

  @IsNumber(
    { maxDecimalPlaces: 2 },
    { message: 'Informe o valor com no máximo 2 casas decimais.' },
  )
  @Min(0, { message: 'O valor não pode ser negativo.' })
  @Max(99_999_999.99, { message: 'Valor muito alto.' })
  valorReferencia!: number;

  @IsInt({ message: 'Informe a duração em dias inteiros.' })
  @Min(1, { message: 'A duração deve ser de pelo menos 1 dia.' })
  @Max(3650, { message: 'A duração pode ser de no máximo 3650 dias.' })
  duracaoDias!: number;
}

export class AlterarStatusPlanoDto {
  @IsIn(['ATIVO', 'INATIVO'], { message: 'Status inválido.' })
  status!: 'ATIVO' | 'INATIVO';
}
