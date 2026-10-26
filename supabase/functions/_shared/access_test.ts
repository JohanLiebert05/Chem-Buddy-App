import {AccessError, requireUser, requireAdmin, requireAiBudget} from "./access.ts";

function check(value: unknown, message: string) {
  if (!value) throw new Error(message);
}
async function rejects(action: () => Promise<unknown>, status: number) {
  try { await action(); } catch (error) {
    check(error instanceof AccessError && error.status === status, "Unexpected rejection");
    return;
  }
  throw new Error("Expected rejection");
}
const userId = "00000000-0000-4000-8000-000000000001";
const request = () => new Request("https://example.test", {headers: {Authorization: "Bearer user-token"}});
function setup(responses: Array<unknown>) {
  for (const key of ["SUPABASE_URL", "SUPABASE_ANON_KEY", "SUPABASE_SERVICE_ROLE_KEY"]) {
    Deno.env.set(key, key === "SUPABASE_URL" ? "https://example.test" : "test-only");
  }
  const original = globalThis.fetch;
  const calls: string[] = [];
  globalThis.fetch = (async (input: string | URL | Request) => {
    calls.push(String(input));
    const next = responses.shift();
    if (next === undefined) throw new Error("Unexpected request");
    return next instanceof Response ? next : new Response(JSON.stringify(next));
  }) as typeof fetch;
  return {calls, restore: () => { globalThis.fetch = original; }};
}

Deno.test("missing authorization never reaches the database", async () => {
  const state = setup([]);
  try {
    await rejects(() => requireUser(new Request("https://example.test")), 401);
    check(state.calls.length === 0, "Unauthorized request made network calls");
  } finally { state.restore(); }
});
Deno.test("invalid JWT is verified with Auth, not decoded locally", async () => {
  const state = setup([new Response("invalid", {status: 401})]);
  try { await rejects(() => requireUser(request()), 401); }
  finally { state.restore(); }
});
Deno.test("a student cannot ingest shared documents", async () => {
  const state = setup([{id: userId}, [{role: "student"}]]);
  try {
    await rejects(() => requireAdmin(request()), 403);
    check(state.calls.length === 2, "Student reached privileged writes");
  } finally { state.restore(); }
});
Deno.test("an administrator is explicitly authorized", async () => {
  const state = setup([{id: userId}, [{role: "admin"}]]);
  try { check((await requireAdmin(request())).admin, "Admin was not authorized"); }
  finally { state.restore(); }
});
Deno.test("exhausted or unavailable quotas fail closed", async () => {
  let state = setup([false]);
  try { await rejects(() => requireAiBudget({id: userId, admin: false}), 429); }
  finally { state.restore(); }
  state = setup([new Response("missing migration", {status: 404})]);
  try { await rejects(() => requireAiBudget({id: userId, admin: false}), 503); }
  finally { state.restore(); }
});
