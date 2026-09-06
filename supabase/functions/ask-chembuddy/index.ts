Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors() });
  }

  try {
    // 1. Verify authentication
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.toLowerCase().startsWith("bearer ")) {
      return json({ error: "Sign in required to ask ChemBuddy." }, 401);
    }

    const userId = getUserIdFromToken(auth);

    // 2. Parse request
    const body = await req.json();
    const question = String(body.question ?? "").trim();
    const subject = body.subject as string | null;
    const documentText = body.document_text as string | null;
    const documentName = (body.document_name as string | null) || "Uploaded PDF";
    const conversationHistory = body.history as Array<{ role: string; content: string }> | null;

    if (question.length < 3) {
      return json({ error: "Please ask a more specific question." }, 400);
    }

    // 3. Supabase credentials
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      return json({ error: "Database is not configured." }, 500);
    }

    const dbHeaders = {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${supabaseServiceKey}`,
      "apikey": supabaseServiceKey,
    };

    // 4. Check AI Usage Limits (if user identified)
    const today = new Date().toISOString().split("T")[0];
    let dailyLimit = 20;

    if (userId) {
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
        console.warn("Usage limit check bypassed due to error:", e);
      }
    }

    // 5. Check AI Response Cache
    const cacheKey = await buildCacheKey([
      question.toLowerCase().trim(),
      subject || "",
      documentName || "",
      String(conversationHistory?.length ?? 0),
    ]);

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
          if (notExpired && entry.response) {
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
      console.warn("Cache lookup bypassed due to error:", e);
    }

    // 6. Generate embedding for RAG search via multi-key rotation
    let chunks: Array<{
      id: string;
      content: string;
      subject: string;
      topic: string;
      page_number: number;
      document_title: string;
      file_name: string;
      similarity: number;
    }> = [];

    try {
      const embeddingModel = Deno.env.get("GEMINI_EMBEDDING_MODEL") || "text-embedding-004";
      const embedRes = await fetchGeminiWithRotation(
        `models/${embeddingModel}:embedContent`,
        {
          model: `models/${embeddingModel}`,
          content: { parts: [{ text: question }] },
          taskType: "RETRIEVAL_QUERY",
        }
      );

      if (embedRes.ok && embedRes.data) {
        const embedding = embedRes.data?.embedding?.values;
        if (Array.isArray(embedding)) {
          const matchRes = await fetch(`${supabaseUrl}/rest/v1/rpc/match_rag_chunks`, {
            method: "POST",
            headers: dbHeaders,
            body: JSON.stringify({
              query_embedding: `[${embedding.join(",")}]`,
              match_count: 6,
              match_threshold: 0.3,
              filter_subject: subject || null,
            }),
          });

          if (matchRes.ok) {
            chunks = await matchRes.json();
          }
        }
      }
    } catch (e) {
      console.warn("RAG retrieval skipped or failed:", e);
    }

    // 7. Build context and sources
    let context = "";
    const sources: Array<{
      documentTitle: string;
      fileName: string;
      subject: string;
      topic: string;
      pageNumber: number;
      similarity: number;
    }> = [];

    if (documentText && documentText.trim().length > 0) {
      sources.push({
        documentTitle: documentName,
        fileName: documentName,
        subject: subject || "Uploaded Material",
        topic: "User Document",
        pageNumber: 1,
        similarity: 1.0,
      });
      context += `[USER STUDY MATERIAL: ${documentName}]\n${documentText.slice(0, 16000)}\n\n---\n\n`;
    }

    if (chunks.length > 0) {
      context += chunks
        .map((c, i) => {
          sources.push({
            documentTitle: c.document_title,
            fileName: c.file_name,
            subject: c.subject || "",
            topic: c.topic || "",
            pageNumber: c.page_number || 0,
            similarity: Math.round(c.similarity * 100) / 100,
          });
          return `[Knowledge Base ${i + 1}: ${c.document_title}${c.page_number ? ` (p.${c.page_number})` : ""}]\n${c.content}`;
        })
        .join("\n\n---\n\n");
    }

    // 8. Build prompt for Gemini
    const systemPrompt = `You are ChemBuddy AI, an expert Chemistry tutor for MSc and BSc Chemistry students.

YOUR PRIMARY MANDATE: Answer the student's EXACT question directly, accurately, and completely. Do NOT give a generic, vague, or off-topic answer. Every response must specifically address what was asked.

FORMATTING RULES:
- Use Markdown formatting: **bold** for key terms, ### for section headings, bullet points for lists.
- Write ALL chemical formulas using LaTeX inline math: $\\text{H}_2\\text{SO}_4$, $\\text{NaOH}$, $\\text{HCl}$, etc.
- Write ALL mathematical equations as display LaTeX on their own line: $$...$$
- Do NOT write raw chemical formulas like H2SO4 — always use $\\text{H}_2\\text{SO}_4$.
- Do NOT show raw LaTeX command strings in plain text.
- Do NOT repeat the user's question back as a heading.
- Do NOT give buffer/concentration/stoichiometry answers when a different topic is asked.

ANSWER STRUCTURE (adapt based on what is asked):
### Direct Answer
[Concise, accurate answer to the exact question]

### Explanation
[Key concepts, mechanisms, or reasoning — specific to the question]

### Key Equations or Reactions (if applicable)
[Balanced equations or formulas in LaTeX only if relevant]

### Exam Key Points
[2–3 concise, exam-focused bullet points about the specific topic]

${context ? `AVAILABLE STUDY CONTEXT (use this as primary reference, supplement with your expertise for gaps):\n${context}` : "Answer from your deep chemistry expertise. Be specific, direct, and accurate. Do NOT give placeholder or generic academic content."}`;

    const contents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

    if (conversationHistory && conversationHistory.length > 0) {
      const last = conversationHistory[conversationHistory.length - 1];
      const skipLast = last?.role === "user" && String(last.content ?? "").trim() === question;
      const hist = skipLast ? conversationHistory.slice(0, -1) : conversationHistory;
      for (const msg of hist.slice(-6)) {
        contents.push({
          role: msg.role === "user" ? "user" : "model",
          parts: [{ text: msg.content }],
        });
      }
    }

    contents.push({
      role: "user",
      parts: [{ text: question }],
    });

    // 9. Generate answer with Gemini multi-key rotation
    const chatModel = Deno.env.get("GEMINI_MODEL") || "gemini-3.8-flash";
    const chatRes = await fetchGeminiWithRotation(
      `models/${chatModel}:generateContent`,
      {
        systemInstruction: { parts: [{ text: systemPrompt }] },
        contents,
        generationConfig: {
          temperature: 0.25,
          maxOutputTokens: 2048,
        },
      }
    );

    if (!chatRes.ok || !chatRes.data) {
      return json({ error: "ChemBuddy could not generate an answer right now.", detail: chatRes.errorText }, 502);
    }

    const answer = chatRes.data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    if (!answer) {
      return json({ error: "ChemBuddy produced an empty response." }, 502);
    }

    const responseData = {
      answer,
      sources: sources.length > 0 ? sources : [],
      hasContext: chunks.length > 0,
      chunksUsed: chunks.length,
      cached: false,
    };

    // 10. Write to Cache & Increment Usage Asynchronously
    const ttlDays = 7;
    const expiresAt = new Date(Date.now() + ttlDays * 24 * 60 * 60 * 1000).toISOString();

    fetch(`${supabaseUrl}/rest/v1/ai_cache`, {
      method: "POST",
      headers: { ...dbHeaders, "Prefer": "resolution=merge-duplicates" },
      body: JSON.stringify({
        cache_key: cacheKey,
        feature: "chat",
        prompt_version: "v1",
        response: responseData,
        user_id: userId,
        source_id: subject || documentName,
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

    return json(responseData);
  } catch (error) {
    console.error("ask-chembuddy error:", error);
    return json(
      { error: "Could not process your question.", detail: String(error) },
      500,
    );
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
      // Clear pending delayed dispatches
      scheduledTimeouts.forEach((t) => clearTimeout(t));
      // Abort other in-flight requests immediately
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

      // Max timeout of 12s per key attempt
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

        // If rate-limited or transient server error, immediately trigger the next key without waiting for the timer!
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
        // Immediately try next key on network error
        if (index + 1 < orderedKeys.length && !settled) {
          dispatchKey(index + 1);
        }
      }
      checkAllFailed();
    }

    // Launch initial key immediately
    dispatchKey(0);

    // Speculative Hedging: If key 0 hasn't responded in 1100ms, start key 1 in parallel.
    // If neither has answered in 2200ms, start key 2 in parallel.
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
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors(), "Content-Type": "application/json" },
  });
}
