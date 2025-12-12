/**
 * Server-side catalog of AuraToken packs.
 * Prices in cents to avoid client-side fraud.
 * Extend or move to Firestore later for dynamic admin control.
 */
export interface TokenPack {
  id: string;
  title: string;
  tokens: number;
  price_cents: number;
  currency: string;
  description: string;
}

export const TOKEN_PACKS: TokenPack[] = [
  {
    id: 'pack_small',
    title: 'Starter Pack',
    tokens: 200,
    price_cents: 500,
    currency: 'usd',
    description: '200 AuraTokens — great to try AI features',
  },
  {
    id: 'pack_medium',
    title: 'Growth Pack',
    tokens: 600,
    price_cents: 1200,
    currency: 'usd',
    description: '600 AuraTokens — best value',
  },
  {
    id: 'pack_large',
    title: 'Pro Pack',
    tokens: 1600,
    price_cents: 2500,
    currency: 'usd',
    description: '1600 AuraTokens — heavy user pack',
  },
];

export function findPackById(packId: string): TokenPack | null {
  return TOKEN_PACKS.find((p) => p.id === packId) ?? null;
}
