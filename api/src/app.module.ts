import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AreaMembroModule } from './area-membro/area-membro.module';
import { AuditoriaController } from './auditoria/auditoria.controller';
import { AuthModule } from './auth/auth.module';
import { BancoModule } from './banco/banco.module';
import { BeneficiosModule } from './beneficios/beneficios.module';
import { MembrosModule } from './membros/membros.module';
import { OrganizacaoController } from './organizacao/organizacao.controller';
import { PerfilModule } from './perfil/perfil.module';
import { PlanosModule } from './planos/planos.module';
import { SaudeController } from './saude.controller';
import { UnidadesModule } from './unidades/unidades.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    BancoModule,
    AuthModule,
    PlanosModule,
    BeneficiosModule,
    MembrosModule,
    UnidadesModule,
    PerfilModule,
    AreaMembroModule,
  ],
  controllers: [SaudeController, AuditoriaController, OrganizacaoController],
})
export class AppModule {}
