// Prepara um banco NOVO para uso real (ex.: Neon): cria as tabelas e as
// regras (01 e 02, sem os dados de teste) e cadastra a organização e o
// primeiro administrador, com uma senha provisória.
//
// Uso (dentro de api/):
//   node scripts/preparar-producao.mjs "<DATABASE_URL>" \
//     --organizacao "Clube Tal" --cnpj 12345678000190 \
//     --admin "Seu Nome" --email voce@gmail.com
//
// Não apaga nada: se o banco já tiver as tabelas, para sem mexer.
import { randomInt } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { parseArgs } from 'node:util';
import bcrypt from 'bcryptjs';
import pg from 'pg';

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    organizacao: { type: 'string' },
    cnpj: { type: 'string' },
    admin: { type: 'string' },
    email: { type: 'string' },
  },
});
const [url] = positionals;
const cnpj = (values.cnpj ?? '').replace(/\D/g, '');
if (
  !url ||
  !values.organizacao ||
  cnpj.length !== 14 ||
  !values.admin ||
  !values.email?.includes('@')
) {
  console.error(
    'Uso: node scripts/preparar-producao.mjs "<DATABASE_URL>" --organizacao "Nome" ' +
      '--cnpj 12345678000190 --admin "Seu Nome" --email voce@exemplo.com',
  );
  process.exit(1);
}

const ALFABETO = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
const senha = Array.from(
  { length: 10 },
  () => ALFABETO[randomInt(ALFABETO.length)],
).join('');

const cliente = new pg.Client({ connectionString: url });
await cliente.connect();
try {
  const { rows } = await cliente.query(
    "SELECT to_regclass('public.organizacao') AS existe",
  );
  if (rows[0].existe) {
    console.error(
      'Este banco já tem as tabelas do MembroPass. Nada foi alterado.',
    );
    process.exitCode = 1;
  } else {
    await cliente.query('BEGIN');
    for (const script of ['01_criacao.sql', '02_regras_negocio.sql']) {
      await cliente.query(
        await readFile(
          new URL(`../database/${script}`, import.meta.url),
          'utf8',
        ),
      );
      console.log(`✔ ${script}`);
    }
    const {
      rows: [org],
    } = await cliente.query(
      "INSERT INTO organizacao (nome, cnpj, status) VALUES ($1, $2, 'HABILITADA') RETURNING id",
      [values.organizacao, cnpj],
    );
    await cliente.query(
      `INSERT INTO administrador (organizacao_id, nome, email, senha_hash, senha_provisoria)
       VALUES ($1, $2, lower($3), $4, true)`,
      [org.id, values.admin, values.email.trim(), await bcrypt.hash(senha, 10)],
    );
    await cliente.query('COMMIT');
    console.log(
      `✔ Organização "${values.organizacao}" e administrador criados.\n`,
    );
    console.log(`  Login: ${values.email.trim().toLowerCase()}`);
    console.log(
      `  Senha provisória: ${senha}  (o app pede uma nova no primeiro acesso)`,
    );
  }
} catch (erro) {
  await cliente.query('ROLLBACK').catch(() => {});
  throw erro;
} finally {
  await cliente.end();
}
