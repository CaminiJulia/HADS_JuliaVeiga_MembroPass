import { Module } from '@nestjs/common';
import { AreaMembroController } from './area-membro.controller';
import { AreaMembroService } from './area-membro.service';
import { QrCarteirinha } from './qr-carteirinha';

@Module({
  controllers: [AreaMembroController],
  providers: [AreaMembroService, QrCarteirinha],
  // O check-in do operador (RF10) vai validar o QR com o mesmo serviço.
  exports: [QrCarteirinha],
})
export class AreaMembroModule {}
