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
    const geminiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
    if (!geminiKey) {
      return json({ error: "Gemini is not configured on the server." }, 500);
    }

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
      "pyq_predict_v1",
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

CRITICAL RULES:
- STRICT GROUNDING: Use ONLY the supplied question paper content as the source of patterns and questions.
- NEVER fabricate probability values or claim "Asked 5 times in previous exams" unless directly verifiable in the uploaded papers.
- Do NOT invent fictional years, question numbers, or false statistical facts.
- If the question papers only support fewer questions than requested, return only the verified questions rather than hallucinating.
- Importance rating: "very_high" (appeared repeatedly / core syllabus anchor), "high" (frequent), "medium" (periodic appearance).
- Question types: "short" (2 marks), "medium" (5 marks), "long" (10 marks), "mechanism" (5 or 10 marks).
- Format chemical reactions and equations using inline LaTeX ($...$).
- Generate 10 to 14 high-yield predicted questions.

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

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-2.0-flash";
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.25,
          maxOutputTokens: 8192,
          responseMimeType: "application/json",
          responseSchema,
        },
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      return json({ error: "Failed to analyze question papers.", detail: errText }, 502);
    }

    const payload = await res.json();
    const rawJson = payload?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

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
          prompt_version: "v1",
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
