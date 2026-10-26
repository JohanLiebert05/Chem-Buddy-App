export class AccessError extends Error {
  constructor(public status: number, message: string) { super(message); }
}
export async function requireUser(req: Request): Promise<{id: string; admin: boolean}> {
  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization.toLowerCase().startsWith("bearer ")) throw new AccessError(401, "Sign in required.");
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !key || !serviceKey) throw new AccessError(503, "Service is not configured.");
  const response = await fetch(url + "/auth/v1/user", {
    headers: {Authorization: authorization, apikey: key},
  });
  if (!response.ok) throw new AccessError(401, "Invalid or expired session.");
  const user = await response.json();
  if (typeof user.id !== "string" || !/^[0-9a-f-]{36}$/i.test(user.id)) throw new AccessError(401, "Invalid session.");
  const profile = await fetch(url + "/rest/v1/profiles?id=eq." +
    encodeURIComponent(user.id) + "&select=role", {
    headers: {Authorization: "Bearer " + serviceKey, apikey: serviceKey},
  });
  if (!profile.ok) throw new AccessError(503, "Unable to verify permissions.");
  const rows = await profile.json();
  return {id: user.id, admin: rows[0]?.role === "admin"};
}
export async function requireAiBudget(user: {id: string; admin: boolean}) {
  if (user.admin) return;
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const response = await fetch(url + "/rest/v1/rpc/consume_ai_request", {
    method: "POST",
    headers: {"Content-Type": "application/json", Authorization: "Bearer " + key, apikey: key},
    body: JSON.stringify({requested_user: user.id}),
  });
  if (!response.ok) throw new AccessError(503, "AI usage protection is unavailable.");
  if (await response.json() !== true) throw new AccessError(429, "Daily AI request limit reached.");
}


export async function requireAdmin(req: Request) {
  const user = await requireUser(req);
  if (!user.admin) throw new AccessError(403, "Only administrators can ingest shared documents.");
  return user;
}
