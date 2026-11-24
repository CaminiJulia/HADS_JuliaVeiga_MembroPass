import type { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import type { Consulta } from '../banco/banco.service';
import type { Papel } from './auth.service';

// Cadastro de cada papel. O nome vai direto no SQL, então só sai desta lista
// fixa, nunca da requisição.
export const TABELA_DA_CONTA: Record<Papel, string> = {
  administrador: 'administrador',
  operador: 'operador',
  membro: 'membro',
};

// Grava uma senha nova. [provisoria]: gerada pelo administrador, o app pede
// outra no primeiro login. Sempre derruba as sessões abertas: a versão da
// sessão sobe, e o guard recusa tokens com a versão antiga. Devolve a nova.
export async function definirSenha(
  consultar: Consulta,
  papel: Papel,
  id: string,
  senha: string,
  { provisoria }: { provisoria: boolean },
) {
  const hash = await bcrypt.hash(senha, 10);
  const [linha] = await consultar<{ versao_sessao: number }>(
    `UPDATE ${TABELA_DA_CONTA[papel]}
     SET senha_hash = $2, senha_provisoria = $3, versao_sessao = versao_sessao + 1
     WHERE id = $1
     RETURNING versao_sessao`,
    [id, hash, provisoria],
  );
  return linha.versao_sessao;
}

// Token de login. `sub` é o id da conta no cadastro do papel; `sv` é a
// versão da sessão, conferida pelo guard a cada requisição.
export function emitirToken(
  jwt: JwtService,
  conta: { id: string; papel: Papel; organizacaoId: string },
  versaoSessao: number,
) {
  return jwt.signAsync({
    sub: conta.id,
    papel: conta.papel,
    organizacaoId: conta.organizacaoId,
    sv: versaoSessao,
  });
}
