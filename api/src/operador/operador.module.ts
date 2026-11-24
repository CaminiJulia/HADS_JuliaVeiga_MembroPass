import { Module } from '@nestjs/common';
import { AreaMembroModule } from '../area-membro/area-membro.module';
import { OperadorController } from './operador.controller';
import { OperadorService } from './operador.service';

@Module({
  imports: [AreaMembroModule],
  controllers: [OperadorController],
  providers: [OperadorService],
})
export class OperadorModule {}
