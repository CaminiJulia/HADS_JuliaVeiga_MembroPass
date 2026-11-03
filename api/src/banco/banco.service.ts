import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool, QueryResultRow } from 'pg';

// Acesso ao PostgreSQL com SQL puro, por um pool de conexões do `pg`.
@Injectable()
export class BancoService implements OnModuleDestroy {
  private readonly pool: Pool;

  constructor(config: ConfigService) {
    this.pool = new Pool({
      connectionString: config.getOrThrow<string>('DATABASE_URL'),
    });
  }

  // Executa uma consulta parametrizada ($1, $2, ...) e devolve as linhas.
  async consultar<T extends QueryResultRow>(
    sql: string,
    parametros: unknown[] = [],
  ): Promise<T[]> {
    const resultado = await this.pool.query<T>(sql, parametros);
    return resultado.rows;
  }

  async onModuleDestroy() {
    await this.pool.end();
  }
}
