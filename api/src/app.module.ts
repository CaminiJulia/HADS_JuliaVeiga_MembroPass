import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { BancoModule } from './banco/banco.module';
import { PlanosModule } from './planos/planos.module';
import { SaudeController } from './saude.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    BancoModule,
    AuthModule,
    PlanosModule,
  ],
  controllers: [SaudeController],
})
export class AppModule {}
