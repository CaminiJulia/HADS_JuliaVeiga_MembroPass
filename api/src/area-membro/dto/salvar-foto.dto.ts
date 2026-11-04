import { IsBase64, IsIn, ValidateIf } from 'class-validator';

export class SalvarFotoDto {
  // null remove a foto. Texto: nova foto em base64.
  @ValidateIf((_, valor) => valor !== null)
  @IsBase64({}, { message: 'Foto inválida.' })
  foto!: string | null;

  @ValidateIf((dados: SalvarFotoDto) => typeof dados.foto === 'string')
  @IsIn(['image/png', 'image/jpeg'], {
    message: 'A foto deve ser PNG ou JPEG.',
  })
  fotoTipo?: string;
}
