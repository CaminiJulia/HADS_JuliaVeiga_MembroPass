import { ConflictException } from '@nestjs/common';
import { DatabaseError } from 'pg';

// Converte violação de índice único (código 23505) em 409 com [mensagem].
export async function comUnico<T>(
  mensagem: string,
  operacao: () => Promise<T>,
): Promise<T> {
  try {
    return await operacao();
  } catch (erro) {
    if (erro instanceof DatabaseError && erro.code === '23505') {
      throw new ConflictException(mensagem);
    }
    throw erro;
  }
}
