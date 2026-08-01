const PALETTE = [
  '#5bc0a4',
  '#e8762c',
  '#5b8ff2',
  '#e0b03e',
  '#a45bf2',
  '#4ecdc4',
  '#f2668f',
  '#8fbf5b',
];

export function avatarColor(id) {
  const n = Number(id) || 0;
  return PALETTE[n % PALETTE.length];
}
