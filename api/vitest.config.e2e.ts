import 'dotenv/config';
import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

// Os testes funcionais usam um banco próprio (membropass_test), recriado a cada
// execução com as migrations e os dados de teste. O banco do .env não é alterado.
const url = new URL(process.env.DATABASE_URL ?? '');
url.pathname = '/membropass_test';
process.env.DATABASE_URL = url.toString();

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    globals: true,
    root: './',
    include: ['**/*.e2e-spec.ts'],
    globalSetup: ['./test/preparar-banco.ts'],
    env: { DATABASE_URL: url.toString() },
  },
});
