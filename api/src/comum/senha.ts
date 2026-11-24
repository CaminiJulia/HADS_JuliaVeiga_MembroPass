import { randomInt } from 'node:crypto';

// Sem caracteres que se confundem (0/O, 1/l/I), para ditar a quem recebe.
const ALFABETO_SENHA =
  'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';

// Senha provisória de uma conta nova: o administrador repassa, e a pessoa
// troca no primeiro acesso.
export function gerarSenha(tamanho = 8) {
  return Array.from(
    { length: tamanho },
    () => ALFABETO_SENHA[randomInt(ALFABETO_SENHA.length)],
  ).join('');
}
