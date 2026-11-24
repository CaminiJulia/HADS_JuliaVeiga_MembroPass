import { Module } from '@nestjs/common';
import { OperadoresController } from './operadores.controller';
import { OperadoresService } from './operadores.service';

@Module({
  controllers: [OperadoresController],
  providers: [OperadoresService],
})
export class OperadoresModule {}
