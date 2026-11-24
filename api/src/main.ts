import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { AppModule } from './app.module';

// Segredos que vêm de exemplo no .env.example: em produção a API nem sobe
// com eles, porque quem conhece o segredo consegue forjar tokens e QR Codes.
const SEGREDOS_DE_EXEMPLO = ['troque-este-segredo', ''];

function conferirSegredo() {
  const segredo = process.env.JWT_SECRET ?? '';
  const fraco = SEGREDOS_DE_EXEMPLO.includes(segredo) || segredo.length < 32;
  if (!fraco) return;
  const aviso =
    'JWT_SECRET fraco ou de exemplo (use 32+ caracteres aleatórios). Veja como gerar no .env.example.';
  if (process.env.NODE_ENV === 'production') throw new Error(aviso);
  new Logger('Seguranca').warn(aviso);
}

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  // Depois de criar: o ConfigModule é que carrega o .env.
  conferirSegredo();
  // Cabeçalhos de segurança padrão (sem cache de respostas sensíveis, sem
  // revelar o framework, etc.).
  app.use(helmet());
  // O logo da organização (até 512 KB) vem em base64 no JSON.
  app.useBodyParser('json', { limit: '1mb' });
  app.enableCors();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
