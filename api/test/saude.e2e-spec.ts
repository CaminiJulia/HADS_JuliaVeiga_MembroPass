import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { configurarApp } from '../src/configurar-app.js';

// Teste funcional (caixa-preta): requer o banco de dados rodando (docker compose up -d).
describe('GET /api/saude', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    configurarApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('informa que a API está no ar e conectada ao banco', () => {
    return request(app.getHttpServer())
      .get('/api/saude')
      .expect(200)
      .expect({ status: 'ok', banco: 'conectado' });
  });
});
