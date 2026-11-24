import { applyDecorators } from '@nestjs/common';
import {
  IsEmail,
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

// Regra de toda senha nova: 8 a 72 caracteres (o bcrypt ignora o que passa
// de 72), com letras e números.
const NovaSenha = () =>
  applyDecorators(
    IsString(),
    MinLength(8, {
      message: 'A nova senha precisa ter pelo menos 8 caracteres.',
    }),
    MaxLength(72, {
      message: 'A nova senha pode ter no máximo 72 caracteres.',
    }),
    Matches(/(?=.*[A-Za-z])(?=.*\d)/, {
      message: 'A nova senha precisa ter letras e números.',
    }),
  );

export class TrocarSenhaDto {
  @IsString()
  @IsNotEmpty({ message: 'Informe sua senha atual.' })
  senhaAtual!: string;

  @NovaSenha()
  novaSenha!: string;
}

export class RedefinirSenhaDto {
  @IsEmail({}, { message: 'Informe um e-mail válido.' })
  email!: string;

  @Matches(/^\d{6}$/, { message: 'O código tem 6 números.' })
  codigo!: string;

  @NovaSenha()
  novaSenha!: string;
}
