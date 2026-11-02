/** Model failures must not disable a credential for every Gemini endpoint. */
export function isGeminiCoolingDown(
  cooldowns: Map<string, number>, endpoint: string, key: string, now = Date.now(),
): boolean {
  return (cooldowns.get(key) ?? 0) > now ||
    (cooldowns.get(JSON.stringify([endpoint, key])) ?? 0) > now;
}
export function recordGeminiFailure(
  cooldowns: Map<string, number>, endpoint: string, key: string, status: number, now = Date.now(),
): void {
  if (![401, 403, 404, 429].includes(status)) return;
  // A rejected credential is global. Model access, missing models and model
  // quotas are scoped to that endpoint so a different model can still work.
  const scope = status === 401 ? key : JSON.stringify([endpoint, key]);
  cooldowns.set(scope, now + (status === 429 ? 60000 : 300000));
}
