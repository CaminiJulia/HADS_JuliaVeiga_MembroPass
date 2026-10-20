// Bloqueio temporário do login após tentativas inválidas seguidas (RF01, HU02).
// O controle é por e-mail e fica em memória: zera quando a API reinicia e não é
// compartilhado entre instâncias, o que basta para o MVP com uma única instância.

export const MAXIMO_TENTATIVAS = 5;
export const DURACAO_BLOQUEIO_MS = 15 * 60 * 1000;
const LIMITE_REGISTROS = 10_000;

interface Registro {
  falhas: number;
  bloqueadoAte?: number;
}

export class TentativasLogin {
  private readonly registros = new Map<string, Registro>();

  // Minutos que faltam para liberar o e-mail, ou 0 se não estiver bloqueado.
  minutosDeBloqueio(email: string, agora = Date.now()): number {
    const registro = this.registros.get(email);
    if (!registro?.bloqueadoAte) return 0;
    if (registro.bloqueadoAte <= agora) {
      this.registros.delete(email);
      return 0;
    }
    return Math.ceil((registro.bloqueadoAte - agora) / 60_000);
  }

  registrarFalha(email: string, agora = Date.now()): void {
    if (this.registros.size >= LIMITE_REGISTROS) this.descartarExpirados(agora);

    const registro = this.registros.get(email) ?? { falhas: 0 };
    registro.falhas += 1;
    if (registro.falhas >= MAXIMO_TENTATIVAS) {
      registro.falhas = 0;
      registro.bloqueadoAte = agora + DURACAO_BLOQUEIO_MS;
    }
    this.registros.set(email, registro);
  }

  // Login bem-sucedido zera a contagem.
  limpar(email: string): void {
    this.registros.delete(email);
  }

  // Evita que e-mails aleatórios façam o mapa crescer sem limite.
  private descartarExpirados(agora: number) {
    for (const [email, registro] of this.registros) {
      if (!registro.bloqueadoAte || registro.bloqueadoAte <= agora) this.registros.delete(email);
    }
  }
}
