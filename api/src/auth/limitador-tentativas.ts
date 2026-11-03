// Bloqueia temporariamente o login de um e-mail após várias tentativas
// malsucedidas seguidas (RF01 — Segurança). Mesma regra do app, mas aqui
// é a API quem garante a segurança de fato.
export class LimitadorTentativas {
  private readonly falhas = new Map<string, number>();
  private readonly bloqueadoAte = new Map<string, number>();

  constructor(
    private readonly maximoTentativas = 5,
    private readonly tempoBloqueioMs = 60_000,
    private readonly agora: () => number = Date.now,
  ) {}

  // Milissegundos que faltam para liberar o e-mail, ou `null` se não está bloqueado.
  tempoRestante(email: string): number | null {
    const chave = this.chave(email);
    const ate = this.bloqueadoAte.get(chave);
    if (ate === undefined) return null;

    const restante = ate - this.agora();
    if (restante > 0) return restante;

    this.limpar(email);
    return null;
  }

  registrarFalha(email: string) {
    const chave = this.chave(email);
    const falhas = (this.falhas.get(chave) ?? 0) + 1;
    this.falhas.set(chave, falhas);
    if (falhas >= this.maximoTentativas) {
      this.bloqueadoAte.set(chave, this.agora() + this.tempoBloqueioMs);
    }
  }

  limpar(email: string) {
    const chave = this.chave(email);
    this.falhas.delete(chave);
    this.bloqueadoAte.delete(chave);
  }

  private chave(email: string) {
    return email.trim().toLowerCase();
  }
}
