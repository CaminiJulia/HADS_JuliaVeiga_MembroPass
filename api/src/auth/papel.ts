// Os três papéis de usuário do DVP v2.4+ (RF02), cada um com o seu cadastro de acesso.
export const Papel = {
  ADMINISTRADOR: 'administrador',
  OPERADOR: 'operador',
  MEMBRO: 'membro',
} as const;

export type Papel = (typeof Papel)[keyof typeof Papel];

export const TODOS_OS_PAPEIS = Object.values(Papel);

// Quem está autenticado na requisição. organizacaoId é a base do isolamento
// multi-tenant (RNF01): toda consulta deve partir dele.
export interface UsuarioAutenticado {
  id: string;
  papel: Papel;
  organizacaoId: string;
}
