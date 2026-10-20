import { Controller, Get, INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { Papeis, UsuarioAtual } from '../src/auth/decorators.js';
import { Papel, type UsuarioAutenticado } from '../src/auth/papel.js';
import { configurarApp } from '../src/configurar-app.js';
import { MAXIMO_TENTATIVAS } from '../src/domain/tentativas-login.js';
import { PrismaService } from '../src/prisma/prisma.service.js';

// Rotas só para o teste, uma por papel, para verificar o controle de acesso (RF02).
@Controller('teste-perfis')
class RotasPorPapel {
  @Get('administrador')
  @Papeis(Papel.ADMINISTRADOR)
  administrador(@UsuarioAtual() usuario: UsuarioAutenticado) {
    return usuario;
  }

  @Get('operador')
  @Papeis(Papel.OPERADOR)
  operador() {
    return { ok: true };
  }

  @Get('sem-papel-declarado')
  semPapel() {
    return { ok: true };
  }
}

// Contas dos dados de teste (database/02_dados_teste.sql).
const SENHA = 'Senha@123';
const ADMIN_CLUBE = 'admin@clubeatletico.com.br';
const ADMIN_EM_HABILITACAO = 'admin@acnorte.com.br';
const OPERADOR_CLUBE = 'portaria@clubeatletico.com.br';
const OPERADOR_ACADEMIA = 'recepcao@academiamovimento.com.br';
const MEMBRO_ATIVO = 'ana.souza@email.com';
const MEMBRO_DESATIVADO = 'gabriela.nunes@email.com';
const CLUBE_ID = 'a0000000-0000-4000-8000-000000000001';

// Testes funcionais (caixa-preta) do login e dos perfis — RF01, RF02, HU02.
describe('Login e perfis', () => {
  let app: INestApplication;
  const api = () => request(app.getHttpServer());

  const login = (email: string, senha = SENHA) =>
    api().post('/api/auth/login').send({ email, senha });

  async function tokenDe(email: string) {
    const resposta = await login(email).expect(200);
    return resposta.body.accessToken as string;
  }

  beforeAll(async () => {
    const modulo = await Test.createTestingModule({
      imports: [AppModule],
      controllers: [RotasPorPapel],
    }).compile();
    app = modulo.createNestApplication();
    configurarApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /api/auth/login', () => {
    it.each([
      [ADMIN_CLUBE, Papel.ADMINISTRADOR],
      [OPERADOR_CLUBE, Papel.OPERADOR],
      [MEMBRO_ATIVO, Papel.MEMBRO],
    ])('localiza %s no cadastro de %s', async (email, papel) => {
      const resposta = await login(email).expect(200);

      expect(resposta.body.accessToken).toEqual(expect.any(String));
      expect(resposta.body.usuario).toMatchObject({ email, papel });
      expect(resposta.body.usuario).not.toHaveProperty('senhaHash');
    });

    it('devolve a identidade visual da organização para o tema do app', async () => {
      const resposta = await login(ADMIN_CLUBE).expect(200);
      expect(resposta.body.usuario.organizacao).toMatchObject({
        id: CLUBE_ID,
        status: 'HABILITADA',
        corPrincipal: '#1E3A8A',
      });
    });

    it('ignora maiúsculas e espaços no e-mail', async () => {
      await login('  Admin@ClubeAtletico.com.br ').expect(200);
    });

    it('usa a mesma mensagem para senha errada e e-mail inexistente', async () => {
      const senhaErrada = await login(ADMIN_CLUBE, 'errada').expect(401);
      const inexistente = await login('ninguem@email.com').expect(401);
      expect(senhaErrada.body.message).toBe('E-mail ou senha inválidos.');
      expect(inexistente.body.message).toBe(senhaErrada.body.message);
    });

    it('recusa cadastro inativo', async () => {
      const resposta = await login(MEMBRO_DESATIVADO).expect(403);
      expect(resposta.body.message).toContain('inativo');
    });

    it('valida os campos obrigatórios', async () => {
      await api().post('/api/auth/login').send({ email: 'nao-e-email' }).expect(400);
    });

    it('bloqueia temporariamente após tentativas inválidas seguidas', async () => {
      for (let i = 0; i < MAXIMO_TENTATIVAS; i++) {
        await login(OPERADOR_ACADEMIA, 'errada').expect(401);
      }
      const resposta = await login(OPERADOR_ACADEMIA).expect(429);
      expect(resposta.body.message).toContain('Tente novamente em 15 minuto(s)');
    });
  });

  describe('GET /api/auth/eu', () => {
    it('devolve o perfil de quem está logado', async () => {
      const token = await tokenDe(OPERADOR_CLUBE);
      const resposta = await api().get('/api/auth/eu').auth(token, { type: 'bearer' }).expect(200);
      expect(resposta.body).toMatchObject({ email: OPERADOR_CLUBE, papel: Papel.OPERADOR });
    });

    it('exige token válido', async () => {
      await api().get('/api/auth/eu').expect(401);
      await api().get('/api/auth/eu').auth('token-falso', { type: 'bearer' }).expect(401);
    });

    it('encerra a sessão de quem foi desativado depois do login', async () => {
      const prisma = app.get(PrismaService);
      const token = await tokenDe('bruno.lima@email.com');

      await prisma.membro.update({
        where: { email: 'bruno.lima@email.com' },
        data: { status: 'DESATIVADO' },
      });

      await api().get('/api/auth/eu').auth(token, { type: 'bearer' }).expect(401);
    });
  });

  describe('Controle de acesso por papel', () => {
    it('libera a rota para o papel autorizado, com a organização do usuário', async () => {
      const token = await tokenDe(ADMIN_CLUBE);
      const resposta = await api()
        .get('/api/teste-perfis/administrador')
        .auth(token, { type: 'bearer' })
        .expect(200);
      expect(resposta.body).toMatchObject({ papel: Papel.ADMINISTRADOR, organizacaoId: CLUBE_ID });
    });

    it.each([
      ['operador', OPERADOR_CLUBE, '/api/teste-perfis/administrador'],
      ['membro', MEMBRO_ATIVO, '/api/teste-perfis/administrador'],
      ['administrador', ADMIN_CLUBE, '/api/teste-perfis/operador'],
    ])('nega ao %s a rota de outro papel', async (_papel, email, rota) => {
      const token = await tokenDe(email);
      await api().get(rota).auth(token, { type: 'bearer' }).expect(403);
    });

    it('nega por padrão a rota que não declara papéis', async () => {
      const token = await tokenDe(ADMIN_CLUBE);
      await api()
        .get('/api/teste-perfis/sem-papel-declarado')
        .auth(token, { type: 'bearer' })
        .expect(403);
    });
  });

  describe('Organização em habilitação (RF03)', () => {
    it('o administrador entra e consulta o próprio perfil', async () => {
      const token = await tokenDe(ADMIN_EM_HABILITACAO);
      const resposta = await api().get('/api/auth/eu').auth(token, { type: 'bearer' }).expect(200);
      expect(resposta.body.organizacao.status).toBe('EM_HABILITACAO');
    });

    it('mas não usa o painel até a habilitação', async () => {
      const token = await tokenDe(ADMIN_EM_HABILITACAO);
      const resposta = await api()
        .get('/api/teste-perfis/administrador')
        .auth(token, { type: 'bearer' })
        .expect(403);
      expect(resposta.body.message).toContain('habilitada');
    });
  });
});
