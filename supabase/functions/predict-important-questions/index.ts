Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors() });
  }

  try {
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.toLowerCase().startsWith("bearer ")) {
      return json({ error: "Authorization required to analyze exam questions." }, 401);
    }

    const userId = getUserIdFromToken(auth);
    const body = await req.json();
    const combinedText = String(body.combinedText ?? "").trim();
    const subjectName = String(body.subjectName ?? "Chemistry").trim();
    const universityName = String(body.universityName ?? "University").trim();
    const paperCount = Math.max(Number(body.paperCount) || 3, 1);
    const yearRange = String(body.yearRange ?? "").trim();

    if (combinedText.length < 150) {
      return json({
        error: "Insufficient question paper text provided. Please make sure the uploaded PDFs contain readable text.",
        code: "EMPTY_PAYLOAD",
      }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const dbHeaders = {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${supabaseServiceKey}`,
      "apikey": supabaseServiceKey,
    };

    // 1. Check AI Usage Limits
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

    // 2. Cache check (30-day cache)
    const cacheKey = await buildCacheKey([
      combinedText.slice(0, 4000).toLowerCase().trim(),
      subjectName.toLowerCase().trim(),
      String(paperCount),
      "pyq_predict_v2",
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
            if (notExpired && entry.response?.predicted_questions) {
              fetch(`${supabaseUrl}/rest/v1/ai_cache?cache_key=eq.${cacheKey}`, {
                method: "PATCH",
                headers: dbHeaders,
                body: JSON.stringify({ hit_count: (entry.hit_count || 0) + 1 }),
              }).catch(() => {});

              return json({
                ...entry.response,
                cached: true,
              });
            }
          }
        }
      } catch (e) {
        console.warn("Cache lookup error:", e);
      }
    }

    // 3. Build prompt and schema
    const prompt = `You are an expert MSc Chemistry examination analyst and university professor.
You have been provided with the combined text from ${paperCount} previous year question papers for the subject: "${subjectName}" (${universityName}${yearRange ? `, years: ${yearRange}` : ""}).

Your task:
1. Identify which topics, concepts, and reaction mechanisms appeared MOST FREQUENTLY across all papers.
2. Predict the questions MOST LIKELY to appear in the upcoming examination based on recurring patterns.
3. Categorize predictions by marks weightage (2-Mark short conceptual, 5-Mark explanatory, 10-Mark comprehensive / reaction mechanism).
4. Provide structured model answer hints for each question to guide the student's preparation.

PREVIOUS YEAR PAPERS COMBINED CONTENT:
${combinedText.slice(0, 16000)}`;

    const responseSchema = {
      type: "OBJECT",
      properties: {
        frequently_asked_topics: {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              topic: { type: "STRING" },
              appeared_count: { type: "NUMBER" },
              years: { type: "STRING" },
              importance: { type: "STRING" },
            },
            required: ["topic", "appeared_count", "importance"],
          },
        },
        predicted_questions: {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              question: { type: "STRING" },
              marks: { type: "NUMBER" },
              question_type: { type: "STRING" },
              topic: { type: "STRING" },
              importance: { type: "STRING" },
              reason: { type: "STRING" },
              model_answer_hints: { type: "ARRAY", items: { type: "STRING" } },
            },
            required: ["question", "marks", "question_type", "topic", "importance", "model_answer_hints"],
          },
        },
        topic_frequency_summary: {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              topic: { type: "STRING" },
              frequency: { type: "STRING" },
              recommended_priority: { type: "STRING" },
            },
            required: ["topic", "frequency", "recommended_priority"],
          },
        },
        exam_strategy: { type: "STRING" },
      },
      required: [
        "frequently_asked_topics",
        "predicted_questions",
        "topic_frequency_summary",
        "exam_strategy",
      ],
    };

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-3.8-flash";
    const aiRes = await fetchGeminiWithRotation(
      `models/${model}:generateContent`,
      {
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.25,
          maxOutputTokens: 8192,
          responseMimeType: "application/json",
          responseSchema,
        },
      }
    );

    if (!aiRes.ok || !aiRes.data) {
      return json({ error: "Failed to analyze question papers.", detail: aiRes.errorText }, 502);
    }

    const rawJson = aiRes.data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    let predictionData: any = null;
    try {
      predictionData = JSON.parse(rawJson);
    } catch {
      return json({ error: "Could not parse prediction analysis." }, 502);
    }

    const result = {
      frequently_asked_topics: predictionData?.frequently_asked_topics ?? [],
      predicted_questions: predictionData?.predicted_questions ?? [],
      topic_frequency_summary: predictionData?.topic_frequency_summary ?? [],
      exam_strategy: predictionData?.exam_strategy ?? "Focus on repeated core topics and reaction mechanisms.",
      subjectName,
      universityName,
      paperCount,
      cached: false,
    };

    // 4. Cache (30 days) and record usage
    if (supabaseUrl && supabaseServiceKey) {
      const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      fetch(`${supabaseUrl}/rest/v1/ai_cache`, {
        method: "POST",
        headers: { ...dbHeaders, "Prefer": "resolution=merge-duplicates" },
        body: JSON.stringify({
          cache_key: cacheKey,
          feature: "predict_questions",
          prompt_version: "v2",
          response: result,
          user_id: userId,
          source_id: subjectName,
          hit_count: 0,
          expires_at: expiresAt,
        }),
      }).catch(() => {});

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

    return json(result);
  } catch (error) {
    console.error("predict-important-questions error:", error);
    return json({ error: "Could not analyze question papers.", detail: String(error) }, 500);
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
      }, i * 1100);
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
