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

    const geminiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
    if (!geminiKey) {
      return json({ error: "Gemini is not configured on the server." }, 500);
    }

    const body = await req.json();
    const sourceText = String(body.sourceText ?? "").trim();
    const count = Math.min(Math.max(Number(body.count) || 10, 5), 30);
    const topic = String(body.topic ?? "Chemistry").trim() || "Chemistry";

    // 1. Text payload validation & pre-check
    if (sourceText.length < 30) {
      return json({ 
        error: "The provided document does not contain enough readable text (minimum 30 characters required).",
        code: "EMPTY_PAYLOAD" 
      }, 400);
    }

    // 2. Supabase credentials
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const dbHeaders = {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${supabaseServiceKey}`,
      "apikey": supabaseServiceKey,
    };

    // 3. Usage limit check
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

    // 4. Cache check
    const cacheKey = await buildCacheKey([
      sourceText.slice(0, 3000).toLowerCase().trim(),
      String(count),
      topic.toLowerCase().trim(),
      "flashcards_v1",
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

    // 5. Smart chunking / truncation to 12,000 characters
    const clipped = sourceText.length > 12000 ? sourceText.slice(0, 12000) : sourceText;

    const prompt = `You are an expert MSc Chemistry academic tutor creating rigorous, exam-quality active-recall flashcards based strictly on the uploaded document.

Target Subject/Document: ${topic}

CRITICAL RULES:
1. STRICT PDF GROUNDING: Use ONLY the supplied document content as the source of factual information and question content. Do not introduce facts, reactions, examples, definitions, mechanisms, named reactions, or questions that are absent from the supplied document.
2. QUESTION COUNT: If the requested number of questions (${count}) cannot be supported by the document, return fewer questions rather than hallucinating. For example, if the document only supports 7 questions, generate 7 high-quality questions and set "limit_note" to "Only 7 document-grounded questions were available from this material." NEVER invent unsupported questions.
3. QUESTION FORMAT: Formulate standalone, high-yield conceptual interrogative questions (e.g., reaction mechanisms, stereochemistry, regioselectivity, rate laws, analytical parameters, instrumentation, and thermodynamic principles).
4. FORBIDDEN: NEVER quote verbatim snippets with trailing ellipses (e.g., NEVER write 'Explain the following point: "..."' or 'What does the document state regarding "..."'). Every question must be a complete, standalone question.
5. ANSWER FORMAT: Provide accurate, comprehensive explanations using clean chemical equations and inline LaTeX notation ($...$) where applicable.
6. KEY TERMS: For each card, provide 3 to 5 mandatory chemical concepts or keywords required for a complete answer.
7. CITATIONS: Whenever possible, link each card to its source paragraph/chunk/topic.

Study Notes:
${clipped}`;

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-2.0-flash";
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;

    const requestPayload = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 8192,
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: {
            limit_note: { type: "STRING", description: "Note explaining if fewer cards were generated due to document content limits" },
            flashcards: {
              type: "ARRAY",
              items: {
                type: "OBJECT",
                properties: {
                  question: { type: "STRING", description: "Standalone conceptual interrogative question" },
                  answer: { type: "STRING", description: "Accurate, comprehensive explanation with chemical/LaTeX notation" },
                  key_terms: {
                    type: "ARRAY",
                    items: { type: "STRING" },
                    description: "3 to 5 mandatory chemical concepts/keywords required for a complete answer"
                  },
                  explanation: { type: "STRING", description: "Optional brief context or exam tip" },
                  topic: { type: "STRING", description: "Chemistry sub-discipline or specific topic" },
                  source_chunk_id: { type: "STRING", description: "Traceable source chunk ID or excerpt identifier" },
                  source_page: { type: "NUMBER", description: "Estimated source page number if identifiable" }
                },
                required: ["question", "answer", "key_terms", "topic"]
              }
            }
          },
          required: ["flashcards"]
        }
      }
    };

    // 6. Exponential backoff retry loop for network resilience
    let aiResponse = null;
    let lastErrorDetail = "";
    let lastStatusCode = 500;

    for (let attempt = 0; attempt <= 2; attempt++) {
      if (attempt > 0) {
        await new Promise((resolve) => setTimeout(resolve, attempt * 1000));
      }

      try {
        const res = await fetch(url, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(requestPayload),
        });

        lastStatusCode = res.status;
        if (res.ok) {
          aiResponse = await res.json();
          break;
        } else {
          lastErrorDetail = await res.text();
          console.error(`Gemini attempt ${attempt + 1} failed [HTTP ${res.status}]:`, lastErrorDetail);
          if (res.status !== 429 && res.status < 500) {
            break;
          }
        }
      } catch (err) {
        lastErrorDetail = String(err);
        console.error(`Gemini fetch error on attempt ${attempt + 1}:`, err);
      }
    }

    if (!aiResponse) {
      return json({
        error: lastStatusCode === 429 
          ? "Gemini API rate limit reached. Please wait a moment and retry." 
          : "Gemini could not generate flashcards right now.",
        detail: lastErrorDetail,
        status: lastStatusCode
      }, lastStatusCode >= 400 && lastStatusCode < 600 ? lastStatusCode : 502);
    }

    // 7. Inspect finishReason
    const candidate = aiResponse?.candidates?.[0];
    const finishReason = candidate?.finishReason;

    if (finishReason && finishReason !== "STOP") {
      console.warn("Gemini generation finishReason:", finishReason);
      if (finishReason === "SAFETY") {
        return json({ error: "Flashcard generation was stopped by content safety filters.", finishReason }, 422);
      }
      if (finishReason === "RECITATION") {
        return json({ error: "Flashcard generation stopped due to strict recitation protection.", finishReason }, 422);
      }
    }

    const rawText = candidate?.content?.parts?.[0]?.text ?? "";
    const parsed = parseCards(rawText, topic);

    if (parsed.length === 0) {
      console.error("Failed to parse flashcard JSON from text:", rawText);
      return json({ 
        error: "The AI model response could not be parsed into flashcard structure.", 
        finishReason: finishReason ?? "UNKNOWN",
        rawExcerpt: rawText.slice(0, 300)
      }, 502);
    }

    const finalCards = parsed.slice(0, count);

    // 8. Cache response & update usage
    if (supabaseUrl && supabaseServiceKey) {
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
      fetch(`${supabaseUrl}/rest/v1/ai_cache`, {
        method: "POST",
        headers: { ...dbHeaders, "Prefer": "resolution=merge-duplicates" },
        body: JSON.stringify({
          cache_key: cacheKey,
          feature: "flashcards",
          prompt_version: "v1",
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
    
    if (!data) {
      const startArr = text.indexOf("[");
      const endArr = text.lastIndexOf("]");
      if (startArr >= 0 && endArr > startArr) {
        try {
          const arr = JSON.parse(text.slice(startArr, endArr + 1));
          if (Array.isArray(arr)) {
            data = { flashcards: arr };
          }
        } catch (_) {}
      }
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
      return {
        question: q,
        answer: combinedAnswer,
        topic: top,
        key_terms: terms,
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
