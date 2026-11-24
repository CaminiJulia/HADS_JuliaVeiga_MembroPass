import {
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
  ValidateIf,
} from 'class-validator';

// O operador identifica a carteirinha pelo QR Code ou, se a câmera não ler,
// digitando o número impresso nela. Vem um dos dois, nunca ambos.
export class RegistrarCheckinDto {
  // Só o formato: os ids fixos dos dados de teste não seguem uma versão de
  // UUID, e o @IsUUID os recusaria.
  @Matches(/^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$/i, {
    message: 'Escolha o local do check-in.',
  })
  unidadeEventoId!: string;

  // Texto lido do QR Code da carteirinha.
  @ValidateIf((dados: RegistrarCheckinDto) => dados.numero === undefined)
  @IsString({ message: 'QR Code inválido.' })
  @IsNotEmpty({ message: 'QR Code inválido.' })
  @MaxLength(2000, { message: 'QR Code inválido.' })
  codigo?: string;

  // Número da carteirinha ("Nº 38F29DBA"): 8 caracteres de 0 a 9 e A a F.
  @ValidateIf((dados: RegistrarCheckinDto) => dados.codigo === undefined)
  @Matches(/^[0-9a-f]{8}$/i, {
    message: 'O número da carteirinha tem 8 caracteres (0 a 9 e A a F).',
  })
  numero?: string;
}
