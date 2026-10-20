import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { TentativasLogin } from '../domain/tentativas-login.js';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { ContasService } from './contas.service.js';
import { AutenticacaoGuard } from './guards/autenticacao.guard.js';
import { AutorizacaoGuard } from './guards/autorizacao.guard.js';
import { SenhasService } from './senhas.service.js';

@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({ secret: config.getOrThrow<string>('JWT_SECRET') }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    ContasService,
    SenhasService,
    { provide: TentativasLogin, useValue: new TentativasLogin() },
    // Valem para todas as rotas da API, nesta ordem: primeiro autentica, depois confere o papel.
    { provide: APP_GUARD, useClass: AutenticacaoGuard },
    { provide: APP_GUARD, useClass: AutorizacaoGuard },
  ],
  exports: [ContasService, SenhasService],
})
export class AuthModule {}
