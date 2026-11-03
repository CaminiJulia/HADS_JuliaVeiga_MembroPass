// Apaga e recria o schema "public", rodando os scripts de database/ em ordem.
// Uso: npm run db:recriar   (somente desenvolvimento: apaga todos os dados!)
import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

process.loadEnvFile('.env');

const pasta = fileURLToPath(new URL('../database/', import.meta.url));
const cliente = new pg.Client({ connectionString: process.env.DATABASE_URL });
await cliente.connect();

try {
  await cliente.query('DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;');
  const scripts = (await readdir(pasta)).filter((f) => f.endsWith('.sql')).sort();
  for (const script of scripts) {
    await cliente.query(await readFile(join(pasta, script), 'utf8'));
    console.log(`✔ ${script}`);
  }
} finally {
  await cliente.end();
}
