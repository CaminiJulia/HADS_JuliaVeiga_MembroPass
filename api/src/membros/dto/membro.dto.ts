import { Transform } from 'class-transformer';
import {
  IsDateString,
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

// Texto opcional: tira espaços e transforma vazio em null.
const opcional = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() || null : value;

const MAXIMO_JUSTIFICATIVA = {
  message: 'A justificativa pode ter no máximo 500 caracteres.',
};

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

  @Transform(opcional)
  @IsOptional()
  @Matches(/^[\d\s()+-]{8,20}$/, { message: 'Informe um telefone válido.' })
  telefone?: string | null;

  @IsUUID('all', { message: 'Escolha um plano.' })
  planoId!: string;
}

export class AlterarStatusMembroDto {
  @IsIn(['ATIVO', 'DESATIVADO'], { message: 'Status inválido.' })
  status!: 'ATIVO' | 'DESATIVADO';

  @Transform(opcional)
  @IsOptional()
  @IsString()
  @MaxLength(500, MAXIMO_JUSTIFICATIVA)
  justificativa?: string | null;
}

export class LiberarCicloDto {
  // Padrão: hoje. Não pode ser futura (a função liberar_ciclo valida).
  @IsOptional()
  @IsDateString({ strict: true }, { message: 'Data do pagamento inválida.' })
  dataPagamento?: string;
}

export class BloquearDto {
  @Transform(aparar)
  @IsString()
  @IsNotEmpty({ message: 'Informe o motivo do bloqueio.' })
  @MaxLength(500, MAXIMO_JUSTIFICATIVA)
  justificativa!: string;
}

export class DesbloquearDto {
  @Transform(opcional)
  @IsOptional()
  @IsString()
  @MaxLength(500, MAXIMO_JUSTIFICATIVA)
  justificativa?: string | null;
}

export class BuscarMembrosDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  busca?: string;
}
