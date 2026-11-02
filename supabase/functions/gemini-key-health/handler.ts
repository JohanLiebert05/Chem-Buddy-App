// Return only classifications, never provider messages, project IDs or keys.
function diagnose(error: {message?: unknown; details?: unknown} | undefined) {
  const details = Array.isArray(error?.details) ? error.details : [];
  const message = typeof error?.message === "string" ? error.message.toLowerCase() : "";
  const credential_issue = /leak|compromis/.test(message) ? "blocked_as_leaked" :
    /expir/.test(message) ? "expired" : /invalid|not valid/.test(message) ? "invalid" : null;
  const allowedReasons = new Set(["API_KEY_INVALID", "API_KEY_EXPIRED", "API_KEY_SERVICE_BLOCKED",
    "API_KEY_HTTP_REFERRER_BLOCKED", "API_KEY_IP_ADDRESS_BLOCKED", "SERVICE_DISABLED",
    "ACCESS_TOKEN_EXPIRED", "CREDENTIALS_MISSING", "BILLING_DISABLED", "CONSUMER_INVALID"]);
  const reason = details.find(d => allowedReasons.has(d?.reason))?.reason ?? null;
  const violations = details.flatMap(d => Array.isArray(d?.violations) ? d.violations : []);
  const quotaLabels = violations.map(v => `${v?.quotaMetric ?? ""} ${v?.quotaId ?? ""}`).join(" ");
  const quota_scope = /per.?day/i.test(quotaLabels) ? "daily" :
    /per.?minute/i.test(quotaLabels) ? "minute" : null;
  const zero_quota = violations.some(v => String(v?.quotaValue) === "0");
  const retry = details.find(d => typeof d?.retryDelay === "string" && /^\d+(\.\d{1,3})?s$/.test(d.retryDelay));
  const retry_after_seconds = retry ? Math.min(86400, Number.parseFloat(retry.retryDelay)) : null;
  return {credential_issue, reason, quota_scope, zero_quota, retry_after_seconds};
}

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
  const slots = ["GEMINI_KEY_1", "GEMINI_KEY_2", "GEMINI_KEY_3", "GEMINI_KEY_4", "GEMINI_KEY_5", "GEMINI_KEY_6"];
  let selected = slots;
  const body = await req.json().catch(() => ({}));
  if (body?.key_names !== undefined) {
    if (!Array.isArray(body.key_names) || body.key_names.length === 0 ||
        !body.key_names.every((name: unknown) => typeof name === "string" && slots.includes(name))) {
      return new Response(JSON.stringify({error: "key_names must contain supported Gemini slot names."}), {status: 400, headers});
    }
    selected = [...new Set<string>(body.key_names)];
  }
  const results = [];
  // Check the supported Gemini slots, never unrelated project secrets.
  for (const name of selected) {
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
        error_code: typeof code === "string" && /^[A-Z_]{1,60}$/.test(code) ? code : null,
        ...(!response.ok ? {diagnostics: diagnose(data?.error)} : {})});
    } catch {
      results.push({name, status: "network_or_timeout"});
    }
  }
  return new Response(JSON.stringify({model: "gemini-3.6-flash", results}), {headers});
}
