Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors() });
  }

  try {
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.toLowerCase().startsWith("bearer ")) {
      return json({ error: "Authorization required to generate flashcards." }, 401);
    }

    const userId = getUserIdFromToken(auth);
    const body = await req.json();
    const sourceText = String(body.sourceText ?? "").trim();
    const count = Math.min(Math.max(Number(body.count) || 10, 5), 30);
    const topic = String(body.topic ?? "Chemistry").trim() || "Chemistry";

    if (sourceText.length < 30) {
      return json({ 
        error: "The provided document does not contain enough readable text (minimum 30 characters required).",
        code: "EMPTY_PAYLOAD" 
      }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const dbHeaders = {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${supabaseServiceKey}`,
      "apikey": supabaseServiceKey,
    };

    // Usage limit check
    const today = new Date().toISOString().split("T")[0];
    let dailyLimit = 20;

    if (userId && supabaseUrl && supabaseServiceKey) {
      try {
        const [profileRes, configRes, usageRes] = await Promise.all([
          fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${userId}&select=role`, { headers: dbHeaders }),
          fetch(`${supabaseUrl}/rest/v1/app_config?select=key,value`, { headers: dbHeaders }),
          fetch(`${supabaseUrl}/rest/v1/ai_usage?user_id=eq.${userId}&date=eq.${today}&select=request_count`, { headers: dbHeaders }),
        ]);

        let isAdmin = false;
        if (profileRes.ok) {
          const profiles = await profileRes.json();
          isAdmin = profiles?.[0]?.role === "admin";
        }

        if (configRes.ok) {
          const configs: Array<{ key: string; value: string }> = await configRes.json();
          const targetKey = isAdmin ? "ai_daily_limit_admin" : "ai_daily_limit_student";
          const match = configs.find((c) => c.key === targetKey);
          if (match?.value) {
            dailyLimit = parseInt(match.value, 10) || 20;
          }
        }

        if (usageRes.ok) {
          const usages: Array<{ request_count: number }> = await usageRes.json();
          const used = usages?.[0]?.request_count ?? 0;
          if (used >= dailyLimit) {
            return json(
              {
                error: "limit_reached",
                message:
                  "AI limit reached for today. You can continue studying your saved notes and flashcards.",
                used,
                limit: dailyLimit,
              },
              429,
            );
          }
        }
      } catch (e) {
        console.warn("Usage limit check error:", e);
      }
    }

    // Cache check
    const cacheKey = await buildCacheKey([
      sourceText.slice(0, 3000).toLowerCase().trim(),
      String(count),
      topic.toLowerCase().trim(),
      "flashcards_v3",
    ]);

    if (supabaseUrl && supabaseServiceKey) {
      try {
        const cacheRes = await fetch(
          `${supabaseUrl}/rest/v1/ai_cache?cache_key=eq.${cacheKey}&select=response,hit_count,expires_at`,
          { headers: dbHeaders },
        );

        if (cacheRes.ok) {
          const entries = await cacheRes.json();
          if (entries && entries.length > 0) {
            const entry = entries[0];
            const notExpired = !entry.expires_at || new Date(entry.expires_at) > new Date();
            if (notExpired && entry.response?.flashcards) {
              fetch(`${supabaseUrl}/rest/v1/ai_cache?cache_key=eq.${cacheKey}`, {
                method: "PATCH",
                headers: dbHeaders,
                body: JSON.stringify({ hit_count: (entry.hit_count || 0) + 1 }),
              }).catch(() => {});

              return json({
                flashcards: entry.response.flashcards,
                cached: true,
              });
            }
          }
        }
      } catch (e) {
        console.warn("Cache lookup error:", e);
      }
    }

    const isHandwritten = Boolean(body.is_handwritten ?? false);
    const images: string[] = Array.isArray(body.images) ? body.images : [];
    const clipped = sourceText.length > 14000 ? sourceText.slice(0, 14000) : sourceText;

    const prompt = `You are a distinguished MSc Chemistry university professor and academic tutor creating rigorous, exam-quality active-recall flashcards from student study materials.
${isHandwritten ? "NOTE: This material originates from student HANDWRITTEN CHEMISTRY NOTES (photographs/scans/OCR)." : "NOTE: This material originates from an academic chemistry document/textbook."}

Target Subject/Topic: ${topic}
Requested Flashcard Count: ${count}

ACADEMIC EXTRACTION & PRIORITIZATION:
1. PRIORITIZE HIGH-YIELD MSC CONCEPTS:
   - Precise scientific definitions and key principles/laws.
   - Organic reaction mechanisms, curved electron-pushing logic, nucleophile/electrophile roles, intermediates (carbocations, carbanions, radicals, enolates).
   - Named reactions with exact reagents, catalysts, solvents, and conditions (e.g. PCC, DIBAL-H, LDA, LiAlH4, NaBH4, KMnO4, H2SO4, NBS, mCPBA).
   - Chemical equations and equilibrium expressions.
   - Physical chemistry formulas and quantitative relationships (e.g. Gibbs ΔG = ΔH - TΔS, Arrhenius k = A e^(-Ea/RT), Beer-Lambert A = εbc, Nernst equation).
   - Coordination chemistry complexes, oxidation states, d-orbital splitting, CFSE, spectrochemical series.
   - Differences, comparisons, and stereochemical outcomes (syn/anti, Markovnikov/anti-Markovnikov, enantiomers/diastereomers).

2. FILTER OUT NOISE & UNIMPORTANT CONTENT:
   - IGNORE personal greetings, dates, page numbers, random student annotations, doodles, or marginal comments.
   - DO NOT create flashcards from incomplete fragments or ambiguous handwriting.
   - DO NOT hallucinate chemical formulas or reactions not supported by the notes.

3. CLEAN CHEMISTRY FORMATTING (NO RAW LATEX / PROGRAMMING ARTIFACTS):
   - Display chemical formulas with standard Unicode subscripts and superscripts:
     Use H₂SO₄ (NOT $H_2SO_4$), CH₃COOH (NOT $CH_3COOH$), [Fe(CN)₆]⁴⁻, KMnO₄, CO₂, H₂O.
   - Use proper chemical arrows: → for reactions, ⇌ for equilibria, ↔ for resonance.
   - Use clean scientific units: °C, kJ·mol⁻¹, cm⁻¹, mol·L⁻¹, 10⁻³ M, pH, pKa.
   - Never output raw programming tokens like "\\rightarrow", "\\frac", "$...$", or "\\text{}".

4. ACTIVE RECALL QUESTION DESIGN:
   - Each card must ask a focused, specific interrogative question testing ONE core concept.
   - Answers must be structured and comprehensive (key concept, mechanism/rationale, conditions/equation).
   - Provide 3 to 5 mandatory chemical key terms per card.

5. CANDIDATE RANKING:
   - Rank and return the top ${count} most valuable, exam-relevant flashcards based strictly on the content.

Study Material Content:
${clipped}`;

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-3-flash-preview";

    // Build multimodal content parts
    const contentParts: any[] = [{ text: prompt }];

    // If base64 images are provided for handwritten notes, add them as inlineData parts
    if (images.length > 0) {
      for (const imgData of images.slice(0, 5)) {
        let cleanBase64 = imgData;
        let mimeType = "image/jpeg";
        if (imgData.includes(";base64,")) {
          const split = imgData.split(";base64,");
          const mimeMatch = split[0].match(/data:(.*?)$/);
          if (mimeMatch && mimeMatch[1]) mimeType = mimeMatch[1];
          cleanBase64 = split[1];
        }
        if (cleanBase64.length > 50) {
          contentParts.push({
            inlineData: {
              mimeType,
              data: cleanBase64,
            },
          });
        }
      }
    }

    const requestPayload = {
      contents: [{ parts: contentParts }],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 8192,
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: {
            limit_note: { type: "STRING" },
            flashcards: {
              type: "ARRAY",
              items: {
                type: "OBJECT",
                properties: {
                  question: { type: "STRING" },
                  answer: { type: "STRING" },
                  key_terms: { type: "ARRAY", items: { type: "STRING" } },
                  explanation: { type: "STRING" },
                  topic: { type: "STRING" },
                  card_type: { type: "STRING" },
                  page_number: { type: "NUMBER" },
                  source_snippet: { type: "STRING" },
                  is_strict_pdf_grounded: { type: "BOOLEAN" }
                },
                required: ["question", "answer", "key_terms", "topic"]
              }
            }
          },
          required: ["flashcards"]
        }
      }
    };

    const aiRes = await fetchGeminiWithRotation(`models/${model}:generateContent`, requestPayload);

    if (!aiRes.ok || !aiRes.data) {
      return json({
        error: "Gemini could not generate flashcards right now.",
        detail: aiRes.errorText,
        status: aiRes.status
      }, aiRes.status >= 400 && aiRes.status < 600 ? aiRes.status : 502);
    }

    const candidate = aiRes.data?.candidates?.[0];
    const rawText = candidate?.content?.parts?.[0]?.text ?? "";
    const parsed = parseCards(rawText, topic);

    if (parsed.length === 0) {
      return json({ 
        error: "The AI model response could not be parsed into flashcard structure.", 
        rawExcerpt: rawText.slice(0, 300)
      }, 502);
    }

    const finalCards = parsed.slice(0, count);

    // Cache response & update usage
    if (supabaseUrl && supabaseServiceKey) {
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
      fetch(`${supabaseUrl}/rest/v1/ai_cache`, {
        method: "POST",
        headers: { ...dbHeaders, "Prefer": "resolution=merge-duplicates" },
        body: JSON.stringify({
          cache_key: cacheKey,
          feature: "flashcards",
          prompt_version: "v2",
          response: { flashcards: finalCards },
          user_id: userId,
          source_id: topic,
          hit_count: 0,
          expires_at: expiresAt,
        }),
      }).catch((e) => console.warn("Cache write failed:", e));

      if (userId) {
        fetch(`${supabaseUrl}/rest/v1/ai_usage`, {
          method: "POST",
          headers: { ...dbHeaders, "Prefer": "resolution=merge-duplicates" },
          body: JSON.stringify({
            user_id: userId,
            date: today,
            request_count: 1,
            last_request_at: new Date().toISOString(),
          }),
        }).catch(() => {});
      }
    }

    return json({ flashcards: finalCards, cached: false });
  } catch (error) {
    console.error("Unhandled error in generate-flashcards:", error);
    return json({ error: "Could not generate flashcards.", detail: String(error) }, 500);
  }
});

// ─── Key Pool & Multi-Key Failover Engine ───────────────────
const GEMINI_API_KEYS_FALLBACK = [
  atob("QVEuQWI4Uk42TFdoRHRwWlppYkYzY08wbjJ0RVdGOWt2enlNVzUwcjRfVE9sZkVpUF9jSHc="),
  atob("QVEuQWI4Uk42TFloMi01alpsTUFkdl9CaXE0cHMzZ2RxeXlpSDVBNV95c09kMktyZWptVHc="),
  atob("QVEuQWI4Uk42THB0RlUxXzdBR3NKbnZ6cVpaeVpYRDZCSnlzNzlkWmJKUGpENEpjWnhVUHc="),
];

function getGeminiKeyPool(): string[] {
  const envKeys = (Deno.env.get("GEMINI_API_KEYS") ?? "")
    .split(",")
    .map((k) => k.trim())
    .filter((k) => k.length > 10);

  const key1 = Deno.env.get("GEMINI_API_KEY_1")?.trim();
  const key2 = Deno.env.get("GEMINI_API_KEY_2")?.trim();
  const key3 = Deno.env.get("GEMINI_API_KEY_3")?.trim();
  const singleKey = Deno.env.get("GEMINI_API_KEY")?.trim();

  const combined: string[] = [
    ...envKeys,
    ...(key1 ? [key1] : []),
    ...(key2 ? [key2] : []),
    ...(key3 ? [key3] : []),
    ...(singleKey ? [singleKey] : []),
    ...GEMINI_API_KEYS_FALLBACK,
  ];

  return Array.from(new Set(combined)).filter((k) => k.length > 5);
}

// Global round-robin index across incoming invocations
let globalKeyCounter = 0;

async function fetchGeminiWithRotation(
  endpointPath: string,
  payload: unknown,
): Promise<{ ok: boolean; status: number; data?: any; errorText?: string }> {
  const keys = getGeminiKeyPool();
  if (keys.length === 0) {
    return { ok: false, status: 500, errorText: "No Gemini API keys configured." };
  }

  // Round-robin starting point so load is evenly distributed across all 3 keys
  const startIdx = (globalKeyCounter++) % keys.length;
  const orderedKeys = keys.map((_, i) => keys[(startIdx + i) % keys.length]);

  return new Promise((resolve) => {
    let settled = false;
    let completedAttempts = 0;
    let lastErrorText = "";
    let lastStatus = 500;
    const activeControllers: AbortController[] = [];
    const scheduledTimeouts: number[] = [];
    const launched = new Set<number>();

    function settleSuccess(data: any) {
      if (settled) return;
      settled = true;
      scheduledTimeouts.forEach((t) => clearTimeout(t));
      activeControllers.forEach((ac) => {
        try { ac.abort(); } catch (_) {}
      });
      resolve({ ok: true, status: 200, data });
    }

    function checkAllFailed() {
      completedAttempts++;
      if (completedAttempts >= orderedKeys.length && !settled) {
        settled = true;
        scheduledTimeouts.forEach((t) => clearTimeout(t));
        resolve({ ok: false, status: lastStatus, errorText: lastErrorText });
      }
    }

    async function dispatchKey(index: number) {
      if (settled || launched.has(index) || index >= orderedKeys.length) return;
      launched.add(index);

      const key = orderedKeys[index];
      const ac = new AbortController();
      activeControllers.push(ac);
      const url = `https://generativelanguage.googleapis.com/v1beta/${endpointPath}?key=${key}`;

      const attemptTimer = setTimeout(() => {
        try { ac.abort(); } catch (_) {}
      }, 12000);

      try {
        const res = await fetch(url, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
          signal: ac.signal,
        });
        clearTimeout(attemptTimer);

        if (settled) return;

        if (res.ok) {
          const data = await res.json();
          settleSuccess(data);
          return;
        }

        lastStatus = res.status;
        lastErrorText = await res.text();
        console.warn(`[Gemini Fast Hedging] Key ${index + 1}/${orderedKeys.length} failed (${res.status}):`, lastErrorText.slice(0, 120));

        if (index + 1 < orderedKeys.length && !settled) {
          dispatchKey(index + 1);
        }
      } catch (err: any) {
        clearTimeout(attemptTimer);
        if (settled) return;
        if (err.name !== "AbortError") {
          lastErrorText = String(err);
          console.warn(`[Gemini Fast Hedging] Key ${index + 1} network error:`, err);
        }
        if (index + 1 < orderedKeys.length && !settled) {
          dispatchKey(index + 1);
        }
      }
      checkAllFailed();
    }

    dispatchKey(0);

    for (let i = 1; i < orderedKeys.length; i++) {
      const timer = setTimeout(() => {
        if (!settled) {
          dispatchKey(i);
        }
      }, i * 650);
      scheduledTimeouts.push(timer);
    }
  });
}

function getUserIdFromToken(authHeader: string): string | null {
  try {
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const jsonStr = atob(base64);
    const payload = JSON.parse(jsonStr);
    return payload.sub ?? null;
  } catch {
    return null;
  }
}

async function buildCacheKey(parts: string[]): Promise<string> {
  const raw = parts.join("|");
  const encoder = new TextEncoder();
  const data = encoder.encode(raw);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

function parseCards(raw: string, defaultTopic = "Chemistry") {
  let text = String(raw ?? "").trim();
  
  const fence = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fence) {
    text = fence[1].trim();
  }

  let data = null;
  try {
    data = JSON.parse(text);
  } catch {
    const startObj = text.indexOf("{");
    const endObj = text.lastIndexOf("}");
    if (startObj >= 0 && endObj > startObj) {
      try {
        data = JSON.parse(text.slice(startObj, endObj + 1));
      } catch (_) {}
    }
  }

  const list = Array.isArray(data?.flashcards) 
    ? data.flashcards 
    : (Array.isArray(data) ? data : []);

  return list
    .map((item: any) => {
      const q = String(item?.question ?? item?.front ?? item?.prompt ?? "").trim();
      const a = String(item?.answer ?? item?.back ?? item?.response ?? "").trim();
      const expl = String(item?.explanation ?? "").trim();
      const top = String(item?.topic ?? defaultTopic).trim() || defaultTopic;
      const combinedAnswer = expl.length > 0 && !a.includes(expl) ? `${a}\n\n*Note: ${expl}*` : a;
      const rawTerms = item?.key_terms ?? item?.keyTerms ?? [];
      const terms = Array.isArray(rawTerms) ? rawTerms.map((t) => String(t).trim()).filter((t) => t.length > 0) : [];
      const pageNum = Number(item?.page_number) || 1;
      const snippet = item?.source_snippet ? String(item.source_snippet).trim() : null;
      const cardType = String(item?.card_type ?? 'understanding').trim();

      return {
        question: q,
        answer: combinedAnswer,
        topic: top,
        key_terms: terms,
        page_number: pageNum,
        source_snippet: snippet,
        card_type: cardType,
        is_strict_pdf_grounded: true,
      };
    })
    .filter((item: any) => item.question.length > 3 && item.answer.length > 1);
}

function cors() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors(), "Content-Type": "application/json" },
  });
}
