import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool, PoolClient, QueryResultRow, types } from 'pg';

// DATE chega como texto 'AAAA-MM-DD'. Sem isso o pg cria um Date à meia-noite
// local, e o fuso horário pode trocar o dia ao converter para JSON.
types.setTypeParser(types.builtins.DATE, (valor) => valor);

// Executa SQL parametrizado ($1, $2, ...) e devolve as linhas.
export type Consulta = <T extends QueryResultRow>(
  sql: string,
  parametros?: unknown[],
) => Promise<T[]>;

// Acesso ao PostgreSQL com SQL puro, por um pool de conexões do `pg`.
@Injectable()
export class BancoService implements OnModuleDestroy {
  private readonly pool: Pool;

  constructor(config: ConfigService) {
    this.pool = new Pool({
      connectionString: config.getOrThrow<string>('DATABASE_URL'),
    });
  }

  consultar: Consulta = (sql, parametros = []) =>
    executar(this.pool, sql, parametros);

  // Roda [operacao] numa transação: se der erro no meio, nada é gravado.
  async transacao<T>(
    operacao: (consultar: Consulta) => Promise<T>,
  ): Promise<T> {
    const cliente = await this.pool.connect();
    try {
      await cliente.query('BEGIN');
      const resultado = await operacao((sql, parametros = []) =>
        executar(cliente, sql, parametros),
      );
      await cliente.query('COMMIT');
      return resultado;
    } catch (erro) {
      await cliente.query('ROLLBACK');
      throw erro;
    } finally {
      cliente.release();
    }
  }

  async onModuleDestroy() {
    await this.pool.end();
  }
}

async function executar<T extends QueryResultRow>(
  alvo: Pool | PoolClient,
  sql: string,
  parametros: unknown[],
): Promise<T[]> {
  const resultado = await alvo.query<T>(sql, parametros);
  return resultado.rows;
}
