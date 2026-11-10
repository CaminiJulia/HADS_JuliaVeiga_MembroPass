import { Transform } from 'class-transformer';
import {
  Equals,
  IsBase64,
  IsDateString,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  ValidateIf,
} from 'class-validator';

const aparar = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

// Texto opcional: tira espaços e transforma vazio em null.
const opcional = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() || null : value;

export const UFS = [
  'AC',
  'AL',
  'AP',
  'AM',
  'BA',
  'CE',
  'DF',
  'ES',
  'GO',
  'MA',
  'MT',
  'MS',
  'MG',
  'PA',
  'PB',
  'PR',
  'PE',
  'PI',
  'RJ',
  'RN',
  'RS',
  'RO',
  'RR',
  'SC',
  'SP',
  'SE',
  'TO',
];

// Primeiro acesso do membro: confere o nome e preenche contato, endereço e foto.
export class CompletarCadastroDto {
  @Transform(aparar)
  @IsString()
  @IsNotEmpty({ message: 'Informe seu nome.' })
  @MaxLength(150, {
    message: 'O nome pode ter no máximo 150 caracteres.',
  })
  nome!: string;

  // Celular com DDD: 10 ou 11 dígitos, aceitando espaços, parênteses e hífen.
  @Transform(aparar)
  @Matches(/^(?=(?:\D*\d){10,11}\D*$)[\d\s()-]+$/, {
    message: 'Informe um celular válido, com DDD.',
  })
  telefone!: string;

  @IsDateString(
    { strict: true },
    { message: 'Informe sua data de nascimento.' },
  )
  dataNascimento!: string;

  @Transform(aparar)
  @Matches(/^\d{5}-?\d{3}$/, { message: 'Informe um CEP válido.' })
  cep!: string;

  @Transform(aparar)
  @IsString()
  @IsNotEmpty({ message: 'Informe a rua.' })
  @MaxLength(150, {
    message: 'A rua pode ter no máximo 150 caracteres.',
  })
  logradouro!: string;

  @Transform(aparar)
  @IsString()
  @IsNotEmpty({ message: 'Informe o número.' })
  @MaxLength(10, {
    message: 'O número pode ter no máximo 10 caracteres.',
  })
  numero!: string;

  @Transform(opcional)
  @IsOptional()
  @IsString()
  @MaxLength(80, { message: 'O complemento pode ter no máximo 80 caracteres.' })
  complemento?: string | null;

  @Transform(aparar)
  @IsString()
  @IsNotEmpty({ message: 'Informe o bairro.' })
  @MaxLength(80, {
    message: 'O bairro pode ter no máximo 80 caracteres.',
  })
  bairro!: string;

  @Transform(aparar)
  @IsString()
  @IsNotEmpty({ message: 'Informe a cidade.' })
  @MaxLength(80, {
    message: 'A cidade pode ter no máximo 80 caracteres.',
  })
  cidade!: string;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @IsIn(UFS, { message: 'Escolha o estado.' })
  uf!: string;

  // Ausente: mantém a foto atual. Texto: nova foto em base64. A foto é obrigatória.
  @IsOptional()
  @IsBase64({}, { message: 'Foto inválida.' })
  foto?: string;

  @ValidateIf((dados: CompletarCadastroDto) => typeof dados.foto === 'string')
  @IsIn(['image/png', 'image/jpeg'], {
    message: 'A foto deve ser PNG ou JPEG.',
  })
  fotoTipo?: string;

  // O membro precisa declarar que os dados são verdadeiros.
  @Equals(true, {
    message: 'Confirme que as informações são verdadeiras.',
  })
  declaracao!: boolean;
}
