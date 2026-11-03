// RF17: contraste entre a cor da carteirinha e o texto branco, pela fórmula
// da WCAG 2.1. Texto normal precisa de pelo menos 4,5:1 para ser legível.
export const CONTRASTE_MINIMO = 4.5;

function luminancia(hex: string) {
  const canais = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);
  const [r, g, b] = canais.map((c) =>
    c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4,
  );
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

// Contraste da cor [hex] ('#RRGGBB') com o branco, de 1 a 21.
export function contrasteComBranco(hex: string) {
  return 1.05 / (luminancia(hex) + 0.05);
}
