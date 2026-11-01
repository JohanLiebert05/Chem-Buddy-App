export async function keyHealth(req: Request, env: (name: string) => string | undefined, send: typeof fetch = fetch): Promise<Response> {
  const headers = {"Content-Type": "application/json", "Cache-Control": "no-store"};
  const keys = [env("SUPABASE_SERVICE_ROLE_KEY")];
  try {
    const configured = JSON.parse(env("SUPABASE_SECRET_KEYS") ?? "{}");
    keys.push(...Object.values(configured).filter((value): value is string => typeof value === "string"));
  } catch { /* A malformed optional key map never authorizes a request. */ }
  const supplied = [req.headers.get("apikey"), req.headers.get("Authorization")?.replace(/^Bearer /, "")];
  if (!keys.some(key => !!key && supplied.includes(key))) {
    return new Response(JSON.stringify({error: "Project service authorization required."}), {status: 401, headers});
  }
  if (req.method !== "POST") return new Response(JSON.stringify({error: "Use POST."}), {status: 405, headers});
  const results = [];
  // Check the supported Gemini slots, never unrelated project secrets.
  for (const name of ["GEMINI_KEY_1", "GEMINI_KEY_2", "GEMINI_KEY_3", "GEMINI_KEY_4", "GEMINI_KEY_5", "GEMINI_KEY_6"]) {
    const key = env(name)?.trim();
    if (!key) { results.push({name, status: "not_configured"}); continue; }
    try {
      const response = await send("https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent", {
        method: "POST", headers: {"Content-Type": "application/json", "x-goog-api-key": key},
        body: JSON.stringify({contents: [{role: "user", parts: [{text: "Reply only OK."}]}], generationConfig: {maxOutputTokens: 512, temperature: 0}}),
        signal: AbortSignal.timeout(25000),
      });
      const data = await response.json();
      const text = data?.candidates?.[0]?.content?.parts?.some((part: {text?: string}) => typeof part.text === "string" && part.text.trim().length > 0) ?? false;
      const status = response.ok ? (text ? "generation_ok" : "accepted_without_text") :
        response.status === 429 ? "quota_or_rate_limited" :
        response.status === 401 || response.status === 403 ? "authentication_or_permission_failed" :
        response.status === 400 ? "request_rejected" : "provider_error";
      const code = data?.error?.status;
      results.push({name, status, http_status: response.status,
        error_code: typeof code === "string" && /^[A-Z_]{1,60}$/.test(code) ? code : null});
    } catch {
      results.push({name, status: "network_or_timeout"});
    }
  }
  return new Response(JSON.stringify({model: "gemini-3.6-flash", results}), {headers});
}
