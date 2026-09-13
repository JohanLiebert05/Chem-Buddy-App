import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface PredictRequestPayload {
  reactants_smiles?: string;
  reactants?: string;
}

// Global rotation cursor for fair round-robin distribution across keys
let keyCursor = 0;

serve(async (req: Request) => {
  // 1. CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  const url = new URL(req.url);

  // Health-check / ping endpoint
  if (url.pathname.endsWith("/ping") || url.pathname.endsWith("/health")) {
    const keys = getAvailableGeminiKeys();
    return jsonResponse({
      status: "online",
      timestamp: new Date().toISOString(),
      service: "predict-reaction",
      active_keys: keys.length,
    });
  }

  try {
    let payload: PredictRequestPayload;
    try {
      payload = await req.json();
    } catch {
      return jsonResponse({ success: false, error: "Invalid JSON body." }, 400);
    }

    const reactantsSmiles = (payload.reactants_smiles || payload.reactants || "").trim();
    if (!reactantsSmiles) {
      return jsonResponse(
        { success: false, error: "Missing required parameter: reactants_smiles" },
        400
      );
    }

    // 2. Read 4 Gemini Keys (from GEMINI_KEYS comma-separated or individual fallbacks)
    const keys = getAvailableGeminiKeys();
    if (keys.length === 0) {
      return jsonResponse(
        {
          success: false,
          error:
            "No Gemini API keys found. Please set GEMINI_KEYS secret in Supabase Edge Functions.",
        },
        500
      );
    }

    // 3. Query Gemini with 4-Key Failover & Retry on HTTP 429
    const modelName = Deno.env.get("GEMINI_MODEL") || "gemini-1.5-flash";
    const systemInstruction =
      "You are an expert organic reaction outcome engine. Return ONLY the valid SMILES string of the single major organic product. Do not include markdown blocks, notes, or explanations.";

    const promptText = `Reactants: ${reactantsSmiles}\nPredict the single major organic product under standard/reasonable reaction conditions. Return ONLY the canonical or valid SMILES of the major organic product.`;

    const geminiResult = await executeGeminiWithRotation(
      keys,
      modelName,
      systemInstruction,
      promptText
    );

    if (!geminiResult.ok || !geminiResult.text) {
      return jsonResponse(
        {
          success: false,
          error:
            geminiResult.error ||
            "Gemini API quota exhausted or service unavailable across all 4 keys.",
          details: geminiResult.details,
        },
        geminiResult.status || 500
      );
    }

    // 4. Sanitize and Extract Clean SMILES
    const cleanProductSmiles = sanitizeSmiles(geminiResult.text);
    if (!cleanProductSmiles) {
      return jsonResponse(
        {
          success: false,
          error: "Failed to parse a valid product SMILES from AI output.",
          raw_output: geminiResult.text,
        },
        422
      );
    }

    // 5. Fetch 2D Vector SVG from NIH Cactus Cheminformatics API
    let svgData = await fetchCactusSvg(cleanProductSmiles);

    // If Cactus cannot render (e.g. timeout or complex coordination), generate a crisp vector fallback
    if (!svgData) {
      svgData = generateVectorSvgFallback(cleanProductSmiles);
    }

    return jsonResponse({
      success: true,
      product_smiles: cleanProductSmiles,
      svg_data: svgData,
      key_index_used: geminiResult.keyIndexUsed,
      total_keys: keys.length,
      model: modelName,
    });
  } catch (err: any) {
    console.error("[predict-reaction] Unhandled error:", err);
    return jsonResponse(
      { success: false, error: "Internal Server Error", message: err.message },
      500
    );
  }
});

// Helper: Extract all 4 keys from GEMINI_KEYS or fallback individual variables
function getAvailableGeminiKeys(): string[] {
  const keys: string[] = [];

  // 1. Check comma-separated GEMINI_KEYS (Primary requirement)
  const envCsv = Deno.env.get("GEMINI_KEYS");
  if (envCsv && envCsv.trim().length > 0) {
    const parts = envCsv.split(",");
    for (const p of parts) {
      const trimmed = p.trim();
      if (trimmed.length > 5 && !keys.includes(trimmed)) {
        keys.push(trimmed);
      }
    }
  }

  // 2. Fallbacks for individual key names if GEMINI_KEYS wasn't set
  if (keys.length === 0) {
    for (let i = 1; i <= 4; i++) {
      const k = Deno.env.get(`GEMINI_KEY_${i}`);
      if (k && k.trim().length > 5 && !keys.includes(k.trim())) {
        keys.push(k.trim());
      }
    }
  }

  const individualFallbacks = [
    "GEMINI_KEY_A",
    "GEMINI_KEY_B",
    "GEMINI_KEY_C",
    "GEMINI_KEY_D",
    "GEMINI_API_KEY",
  ];
  for (const fb of individualFallbacks) {
    const val = Deno.env.get(fb);
    if (val && val.trim().length > 5 && !keys.includes(val.trim())) {
      keys.push(val.trim());
    }
  }

  return keys;
}

// 4-Key Failover Executor with immediate retry on HTTP 429
async function executeGeminiWithRotation(
  keys: string[],
  model: string,
  systemInstruction: string,
  prompt: string
): Promise<{
  ok: boolean;
  text?: string;
  status?: number;
  error?: string;
  details?: string;
  keyIndexUsed?: number;
}> {
  const startIndex = keyCursor % keys.length;
  keyCursor = (keyCursor + 1) % keys.length;

  let lastError = "";
  let lastDetails = "";
  let lastStatus = 500;

  for (let attempt = 0; attempt < keys.length; attempt++) {
    const keyIndex = (startIndex + attempt) % keys.length;
    const apiKey = keys[keyIndex];

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const body: any = {
      contents: [
        {
          role: "user",
          parts: [{ text: prompt }],
        },
      ],
      systemInstruction: {
        parts: [{ text: systemInstruction }],
      },
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 256,
      },
    };

    try {
      const resp = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(12000),
      });

      if (resp.ok) {
        const data = await resp.json();
        const extracted = extractTextFromGeminiResponse(data);
        if (extracted) {
          return {
            ok: true,
            text: extracted,
            status: 200,
            keyIndexUsed: keyIndex + 1,
          };
        }
      }

      lastStatus = resp.status;
      lastDetails = await resp.text();
      console.warn(
        `[predict-reaction] Gemini key #${keyIndex + 1} failed with HTTP ${resp.status}:`,
        lastDetails.slice(0, 160)
      );

      // On 429 (Resource Exhausted), 503 (Overloaded), or 403 (Forbidden/Invalid), failover to next key
      if (resp.status === 429 || resp.status === 503 || resp.status === 403) {
        lastError = `HTTP ${resp.status} (Rate limited / Quota exhausted). Rotating to next key.`;
        continue;
      }
    } catch (netErr: any) {
      lastError = `Network / timeout error on key #${keyIndex + 1}: ${netErr.message}`;
      console.warn(`[predict-reaction] Net error on key #${keyIndex + 1}:`, netErr);
    }
  }

  return {
    ok: false,
    status: lastStatus,
    error: lastError || "All 4 Gemini keys failed or exhausted quota.",
    details: lastDetails,
  };
}

function extractTextFromGeminiResponse(data: any): string {
  try {
    const candidates = data?.candidates;
    if (candidates && candidates.length > 0) {
      const parts = candidates[0]?.content?.parts;
      if (parts && parts.length > 0) {
        return parts.map((p: any) => p.text || "").join("").trim();
      }
    }
  } catch (_) {}
  return "";
}

function sanitizeSmiles(raw: string): string {
  let s = raw.trim();

  // Strip markdown code fences
  s = s.replace(/```(?:smiles|smi|text)?\n?([\s\S]*?)```/gi, "$1").trim();

  // Strip common label prefixes
  s = s.replace(/^(?:SMILES|Product|Major Product|Result)\s*[:=-]\s*/i, "").trim();

  // If response has multiple lines, take the first non-empty line
  const lines = s
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l.length > 0 && !l.toLowerCase().startsWith("note:"));
  if (lines.length > 0) {
    s = lines[0];
  }

  // Strip quotes and backticks
  s = s.replace(/^["'`]|["'`]$/g, "").trim();

  // Strip trailing periods or punctuation
  s = s.replace(/[.;]+$/, "").trim();

  return s;
}

// Fetch clean 2D vector SVG from NIH Cactus Cheminformatics API
async function fetchCactusSvg(smiles: string): Promise<string> {
  try {
    const encoded = encodeURIComponent(smiles);
    const cactusUrl = `https://cactus.nci.nih.gov/chemical/structure/${encoded}/image?format=svg`;

    const res = await fetch(cactusUrl, {
      headers: {
        "User-Agent": "ChemBuddy-MSc-Predictor/1.0",
        Accept: "image/svg+xml,text/xml,*/*",
      },
      signal: AbortSignal.timeout(7000),
    });

    if (res.ok) {
      const svgText = await res.text();
      if (
        svgText.includes("<svg") ||
        svgText.includes("<SVG") ||
        svgText.includes("xmlns")
      ) {
        return svgText;
      }
    }
  } catch (e) {
    console.warn("[predict-reaction] NIH Cactus API fetch warning:", e);
  }
  return "";
}

// Crisp Vector SVG Fallback with chemical styling
function generateVectorSvgFallback(smiles: string): string {
  const safeSmiles = smiles
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 340 180" width="100%" height="100%">
  <rect width="340" height="180" rx="16" fill="#0F172A" stroke="#334155" stroke-width="1.5"/>
  <circle cx="170" cy="65" r="32" fill="#8B5CF6" fill-opacity="0.15" stroke="#A78BFA" stroke-width="1.5" stroke-dasharray="4 3"/>
  <text x="170" y="72" font-size="24" font-weight="bold" fill="#38BDF8" text-anchor="middle" font-family="sans-serif">⚗️</text>
  <text x="170" y="125" font-size="14" font-weight="700" fill="#E2E8F0" text-anchor="middle" font-family="monospace">${safeSmiles}</text>
  <text x="170" y="148" font-size="11" font-weight="600" fill="#94A3B8" text-anchor="middle" font-family="sans-serif">Predicted Major Product (SMILES)</text>
</svg>`;
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
  };
}

function jsonResponse(data: any, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders(),
      "Content-Type": "application/json",
    },
  });
}
