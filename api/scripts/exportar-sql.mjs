// Copia as migrations do Prisma para os scripts SQL entregues em database/.
// Execute sempre que criar uma nova migration (npm run db:sql).
import { readdir, readFile, writeFile } from 'node:fs/promises';

const migrations = new URL('../prisma/migrations/', import.meta.url);
const database = new URL('../../database/', import.meta.url);

const destinos = [
  { sufixo: '_criacao_tabelas', arquivo: '01_criacao.sql', titulo: 'Criação das tabelas' },
  { sufixo: '_regras_negocio', arquivo: '03_regras_negocio.sql', titulo: 'Regras de negócio: triggers, procedures e views' },
];

const pastas = (await readdir(migrations, { withFileTypes: true })).filter((p) => p.isDirectory()).map((p) => p.name);

for (const { sufixo, arquivo, titulo } of destinos) {
  const pasta = pastas.find((nome) => nome.endsWith(sufixo));
  const sql = await readFile(new URL(`${pasta}/migration.sql`, migrations), 'utf8');
  const cabecalho =
    `-- MembroPass — ${titulo}\n` +
    `-- Gerado a partir de api/prisma/migrations/${pasta} (npm run db:sql).\n\n`;
  await writeFile(new URL(arquivo, database), cabecalho + sql);
  console.log(`database/${arquivo} <- ${pasta}`);
}
