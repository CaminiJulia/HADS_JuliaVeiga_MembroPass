import { IsEmail, IsNotEmpty, IsString } from 'class-validator';

export class LoginDto {
  @IsEmail({}, { message: 'Informe um e-mail válido.' })
  email!: string;

  @IsString()
  @IsNotEmpty({ message: 'Informe sua senha.' })
  senha!: string;
}

export class RecuperarSenhaDto {
  @IsEmail({}, { message: 'Informe um e-mail válido.' })
  email!: string;
}
