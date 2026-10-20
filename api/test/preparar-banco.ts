import { execSync } from 'node:child_process';
import pg from 'pg';

const BANCO_DE_TESTE = 'membropass_test';

// Recria o banco de teste do zero antes dos testes funcionais.
export default async function prepararBanco() {
  const url = new URL(process.env.DATABASE_URL ?? '');
  if (url.pathname !== `/${BANCO_DE_TESTE}`) {
    throw new Error(`Os testes funcionais só podem rodar no banco ${BANCO_DE_TESTE}.`);
  }

  const servidor = new URL(url);
  servidor.pathname = '/postgres';
  const cliente = new pg.Client({ connectionString: servidor.toString() });
  await cliente.connect();
  try {
    await cliente.query(`DROP DATABASE IF EXISTS ${BANCO_DE_TESTE} WITH (FORCE)`);
    await cliente.query(`CREATE DATABASE ${BANCO_DE_TESTE}`);
  } finally {
    await cliente.end();
  }

  const opcoes = { stdio: 'inherit', env: process.env } as const;
  execSync('npx prisma migrate deploy', opcoes);
  execSync('npm run db:seed', opcoes);
}
