import {
  ForbiddenException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { TentativasLogin } from '../domain/tentativas-login.js';
import { StatusOrganizacao } from '../generated/prisma/client.js';
import { Conta, ContasService } from './contas.service.js';
import { Papel } from './papel.js';
import { SenhasService } from './senhas.service.js';

export interface PayloadAcesso {
  sub: string;
  papel: Papel;
}

const EXPIRACAO_PADRAO_SEGUNDOS = 8 * 60 * 60;

// Dados que o app usa para abrir a área do papel e aplicar o tema da organização.
export function perfilDaConta({ id, papel, nome, email, organizacao }: Conta) {
  return { id, papel, nome, email, organizacao };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly contas: ContasService,
    private readonly senhas: SenhasService,
    @Inject(TentativasLogin) private readonly tentativas: TentativasLogin,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  // HU02: login por e-mail e senha nos três cadastros.
  async login(email: string, senha: string) {
    const minutos = this.tentativas.minutosDeBloqueio(email);
    if (minutos > 0) {
      throw new HttpException(
        `Muitas tentativas inválidas. Tente novamente em ${minutos} minuto(s).`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const conta = await this.contas.buscarPorEmail(email);
    const hash = conta?.senhaHash ?? (await this.senhas.hashParaComparacaoFicticia());
    const senhaCorreta = await this.senhas.verificar(senha, hash);
    if (!conta || !senhaCorreta) {
      this.tentativas.registrarFalha(email);
      // Mesma mensagem para e-mail inexistente e senha errada.
      throw new UnauthorizedException('E-mail ou senha inválidos.');
    }
    this.tentativas.limpar(email);

    if (!conta.ativa) {
      throw new ForbiddenException('Cadastro inativo. Procure a sua organização.');
    }
    // O administrador entra mesmo antes da habilitação, para acompanhar o status (HU01).
    if (
      conta.papel !== Papel.ADMINISTRADOR &&
      conta.organizacao.status !== StatusOrganizacao.HABILITADA
    ) {
      throw new ForbiddenException('A organização não está habilitada no momento.');
    }

    // Variáveis de ambiente chegam como texto; sem conversão, o JWT leria milissegundos.
    const expiraEm = Number(this.config.get('JWT_EXPIRACAO_SEGUNDOS') ?? EXPIRACAO_PADRAO_SEGUNDOS);
    const payload: PayloadAcesso = { sub: conta.id, papel: conta.papel };
    return {
      accessToken: await this.jwt.signAsync(payload, { expiresIn: expiraEm }),
      expiraEm,
      usuario: perfilDaConta(conta),
    };
  }

  async perfil(papel: Papel, id: string) {
    const conta = await this.contas.buscarPorId(papel, id);
    if (!conta) throw new UnauthorizedException('Sessão inválida ou expirada.');
    return perfilDaConta(conta);
  }
}
