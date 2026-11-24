import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AreaMembroModule } from './area-membro/area-membro.module';
import { AuditoriaController } from './auditoria/auditoria.controller';
import { AuthModule } from './auth/auth.module';
import { BancoModule } from './banco/banco.module';
import { BeneficiosModule } from './beneficios/beneficios.module';
import { EmailModule } from './email/email.module';
import { MembrosModule } from './membros/membros.module';
import { OperadorModule } from './operador/operador.module';
import { OperadoresModule } from './operadores/operadores.module';
import { OrganizacaoController } from './organizacao/organizacao.controller';
import { PerfilModule } from './perfil/perfil.module';
import { PlanosModule } from './planos/planos.module';
import { SaudeController } from './saude.controller';
import { UnidadesModule } from './unidades/unidades.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    // Limite geral por IP: 300 requisições por minuto. Login e recuperação de
    // senha têm limites próprios, bem menores (ver AuthController).
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 300 }]),
    BancoModule,
    EmailModule,
    AuthModule,
    PlanosModule,
    BeneficiosModule,
    MembrosModule,
    UnidadesModule,
    PerfilModule,
    AreaMembroModule,
    OperadorModule,
    OperadoresModule,
  ],
  controllers: [SaudeController, AuditoriaController, OrganizacaoController],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
