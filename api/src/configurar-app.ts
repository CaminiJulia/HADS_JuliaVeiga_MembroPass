import { INestApplication, ValidationPipe } from '@nestjs/common';

// Configuração compartilhada entre a aplicação e os testes funcionais.
export function configurarApp(app: INestApplication) {
  app.setGlobalPrefix('api');
  app.enableCors();
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
  );
}
