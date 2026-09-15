import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface RequestPayload {
  prompt: string;
  category?: string;
  system_instruction?: string;
  temperature?: number;
  max_output_tokens?: number;
  history?: Array<{ role: string; content: string }>;
}

let keyCursor = 0;

serve(async (req: Request) => {
  // CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  const url = new URL(req.url);

  // Health-check /ping endpoint to prevent database sleeping
  if (url.pathname.endsWith("/ping") || url.pathname.endsWith("/health")) {
    return jsonResponse({
      status: "online",
      timestamp: new Date().toISOString(),
      service: "ask-gemini-orchestrator",
      active_keys: getAvailableGeminiKeys().length,
    });
  }

  try {
    const payload: RequestPayload = await req.json();
    const prompt = (payload.prompt || "").trim();
    const category = (payload.category || "general").toLowerCase().trim();

    if (!prompt) {
      return jsonResponse({ error: "Missing required field: prompt" }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // 1. Check Academic Answer Cache (Sub-50ms Zero-Token Hit)
    const normalizedPrompt = prompt.toLowerCase().replace(/\s+/g, " ");
    const cacheHash = await sha256Hex(`${normalizedPrompt}::${category}`);

    if (supabaseUrl && supabaseServiceKey) {
      try {
        const cacheRes = await fetch(
          `${supabaseUrl}/rest/v1/cached_academic_responses?query_hash=eq.${cacheHash}&select=response_payload,hit_count,id`,
          {
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${supabaseServiceKey}`,
              apikey: supabaseServiceKey,
            },
          }
        );

        if (cacheRes.ok) {
          const cachedData = await cacheRes.json();
          if (cachedData && cachedData.length > 0) {
            const entry = cachedData[0];
            // Async increment hit_count in background
            fetch(`${supabaseUrl}/rest/v1/cached_academic_responses?id=eq.${entry.id}`, {
              method: "PATCH",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${supabaseServiceKey}`,
                apikey: supabaseServiceKey,
              },
              body: JSON.stringify({
                hit_count: (entry.hit_count || 1) + 1,
                last_accessed_at: new Date().toISOString(),
              }),
            }).catch(() => {});

            return jsonResponse({
              ...entry.response_payload,
              cached: true,
              cache_hash: cacheHash,
              hit_count: (entry.hit_count || 1) + 1,
            });
          }
        }
      } catch (cacheErr) {
        console.warn("[Cache] Cache lookup warning:", cacheErr);
      }
    }

    // 2. Fetch with 4-Key Gemini Failover & Rotation
    const keys = getAvailableGeminiKeys();
    if (keys.length === 0) {
      return jsonResponse({ error: "No Gemini API keys configured on server." }, 500);
    }

    const candidateModels = [
      Deno.env.get("GEMINI_MODEL") || "gemini-3-flash-preview",
      "gemini-flash-latest",
      "gemini-3.6-flash",
    ].filter((m, i, arr) => arr.indexOf(m) === i);

    let result: { ok: boolean; data?: any; status?: number; error?: string; keyIndexUsed?: number; modelUsed?: string } = {
      ok: false,
      status: 500,
      error: "No model attempted",
    };

    let modelName = candidateModels[0];
    for (const m of candidateModels) {
      modelName = m;
      result = await executeGeminiWithRotation(keys, m, payload);
      if (result.ok) break;
    }

    if (!result.ok) {
      return jsonResponse(
        { error: "Gemini API exhausted or unavailable across all 4 keys.", details: result.error },
        result.status || 500
      );
    }

    const responseText = extractGeminiText(result.data);
    const finalPayload = {
      text: responseText,
      model: modelName,
      key_index: result.keyIndexUsed,
      total_keys: keys.length,
      cached: false,
    };

    // 3. Persist to Academic Answer Cache for Zero-Token future requests
    if (supabaseUrl && supabaseServiceKey && responseText.length > 20) {
      fetch(`${supabaseUrl}/rest/v1/cached_academic_responses`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${supabaseServiceKey}`,
          apikey: supabaseServiceKey,
          Prefer: "resolution=merge-duplicates",
        },
        body: JSON.stringify({
          query_hash: cacheHash,
          normalized_query: normalizedPrompt,
          prompt_category: category,
          model_version: modelName,
          response_payload: finalPayload,
          tokens_saved: Math.round(responseText.length / 4),
        }),
      }).catch((e) => console.warn("[Cache] Failed to persist academic response:", e));
    }

    return jsonResponse(finalPayload);
  } catch (err: any) {
    return jsonResponse({ error: "Internal Server Error", message: err.message }, 500);
  }
});

// Helper: Extract all 4 keys + fallbacks
function getAvailableGeminiKeys(): string[] {
  const keys: string[] = [];
  for (let i = 1; i <= 4; i++) {
    const k = Deno.env.get(`GEMINI_KEY_${i}`);
    if (k && k.trim().length > 10) keys.push(k.trim());
  }
  // Fallbacks if named differently
  const fallbacks = ["GEMINI_KEY_A", "GEMINI_KEY_B", "GEMINI_KEY_C", "GEMINI_KEY_D", "GEMINI_API_KEY"];
  for (const fb of fallbacks) {
    const val = Deno.env.get(fb);
    if (val && val.trim().length > 10 && !keys.includes(val.trim())) {
      keys.push(val.trim());
    }
  }
  return keys;
}

// 4-Key Failover Executor with immediate retry on 429 / 503
async function executeGeminiWithRotation(
  keys: string[],
  model: string,
  payload: RequestPayload
): Promise<{ ok: boolean; data?: any; status?: number; error?: string; keyIndexUsed?: number }> {
  const startIndex = keyCursor % keys.length;
  keyCursor = (keyCursor + 1) % keys.length;

  let lastError = "";
  let lastStatus = 500;

  for (let attempt = 0; attempt < keys.length; attempt++) {
    const keyIndex = (startIndex + attempt) % keys.length;
    const apiKey = keys[keyIndex];

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const contents: any[] = [];
    if (payload.history && payload.history.length > 0) {
      for (const h of payload.history) {
        contents.push({
          role: h.role === "assistant" ? "model" : "user",
          parts: [{ text: h.content }],
        });
      }
    }
    contents.push({
      role: "user",
      parts: [{ text: payload.prompt }],
    });

    const body: any = {
      contents,
      generationConfig: {
        temperature: payload.temperature ?? 0.3,
        maxOutputTokens: payload.max_output_tokens ?? 4096,
      },
    };

    if (payload.system_instruction) {
      body.systemInstruction = {
        parts: [{ text: payload.system_instruction }],
      };
    }

    try {
      const resp = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      if (resp.ok) {
        const data = await resp.json();
        return { ok: true, data, status: 200, keyIndexUsed: keyIndex + 1 };
      }

      lastStatus = resp.status;
      lastError = await resp.text();
      console.warn(`[Gemini Failover] Key #${keyIndex + 1} returned status ${resp.status}:`, lastError.slice(0, 150));

      // If Rate-limited (429) or Server overloaded (503), immediately try next key
      if (resp.status === 429 || resp.status === 503 || resp.status === 403) {
        continue;
      }
    } catch (netErr: any) {
      lastError = String(netErr);
      console.warn(`[Gemini Failover] Network error on Key #${keyIndex + 1}:`, netErr);
      continue;
    }
  }

  return { ok: false, status: lastStatus, error: lastError };
}

function extractGeminiText(data: any): string {
  try {
    const candidate = data?.candidates?.[0];
    const parts = candidate?.content?.parts;
    if (Array.isArray(parts)) {
      return parts.map((p: any) => p.text || "").join("\n");
    }
    return "";
  } catch {
    return "";
  }
}

async function sha256Hex(str: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(str);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

function jsonResponse(data: any, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders(),
      "Content-Type": "application/json",
    },
  });
}
