// Popula o banco com os dados de teste de database/02_dados_teste.sql.
import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import pg from 'pg';

const sql = await readFile(new URL('../../database/02_dados_teste.sql', import.meta.url), 'utf8');
const client = new pg.Client({ connectionString: process.env.DATABASE_URL });

await client.connect();
try {
  await client.query(sql);
  console.log('Dados de teste inseridos.');
} finally {
  await client.end();
}
