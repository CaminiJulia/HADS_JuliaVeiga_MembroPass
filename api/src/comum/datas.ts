// Datas no formato AAAA-MM-DD usado pelo banco, no fuso local do servidor.
export const Datas = {
  hoje(agora = new Date()): string {
    const dois = (n: number) => String(n).padStart(2, '0');
    return `${agora.getFullYear()}-${dois(agora.getMonth() + 1)}-${dois(agora.getDate())}`;
  },
};
