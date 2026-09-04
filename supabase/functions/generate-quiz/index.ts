Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors() });
  }

  try {
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.toLowerCase().startsWith("bearer ")) {
      return json({ error: "Authorization required to generate quizzes." }, 401);
    }

    const userId = getUserIdFromToken(auth);
    const geminiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
    if (!geminiKey) {
      return json({ error: "Gemini is not configured on the server." }, 500);
    }

    const body = await req.json();
    const sourceText = String(body.sourceText ?? "").trim();
    const questionCount = Math.min(Math.max(Number(body.questionCount) || 10, 5), 25);
    const topic = String(body.topic ?? "Chemistry").trim() || "Chemistry";
    const difficulty = String(body.difficulty ?? "msc_exam").trim();
    const quizType = String(body.quizType ?? "mcq").trim();

    if (sourceText.length < 50) {
      return json({
        error: "Insufficient study material provided (minimum 50 characters required).",
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

    // 2. Cache check
    const cacheKey = await buildCacheKey([
      sourceText.slice(0, 3000).toLowerCase().trim(),
      String(questionCount),
      topic.toLowerCase().trim(),
      difficulty,
      quizType,
      "quiz_v1",
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
            if (notExpired && entry.response?.questions) {
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
    const prompt = `You are an expert MSc Chemistry examiner creating a rigorous quiz for university-level chemistry students.

Subject: ${topic}
Difficulty: ${difficulty} (easy=BSc level, medium=MSc level, hard=competitive exam, msc_exam=end-semester exam pattern)
Quiz Type: ${quizType}
Number of Questions: ${questionCount}

CRITICAL RULES:
1. Base ALL questions strictly on the provided study material below.
2. MCQ options must be plausible and chemically meaningful. Exactly 4 options for each question.
3. Use standard chemical notation and inline LaTeX ($...$) for chemical formulas and equations.
4. Explanations must clearly explain WHY the correct answer is right and why others are incorrect.
5. Generate exactly ${questionCount} questions.

Study Material:
${sourceText.slice(0, 12000)}`;

    const responseSchema = {
      type: "OBJECT",
      properties: {
        quiz_title: { type: "STRING" },
        total_marks: { type: "NUMBER" },
        questions: {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              question: { type: "STRING" },
              question_type: { type: "STRING" },
              difficulty: { type: "STRING" },
              topic: { type: "STRING" },
              options: { type: "ARRAY", items: { type: "STRING" } },
              correct_answer: { type: "STRING" },
              correct_index: { type: "NUMBER" },
              explanation: { type: "STRING" },
              marks: { type: "NUMBER" },
              key_concepts: { type: "ARRAY", items: { type: "STRING" } },
            },
            required: ["question", "options", "correct_answer", "correct_index", "explanation", "marks"],
          },
        },
      },
      required: ["quiz_title", "total_marks", "questions"],
    };

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-2.0-flash";
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 8192,
          responseMimeType: "application/json",
          responseSchema,
        },
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      return json({ error: "Failed to generate quiz with Gemini.", detail: errText }, 502);
    }

    const payload = await res.json();
    const rawJson = payload?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    let quizData: any = null;
    try {
      quizData = JSON.parse(rawJson);
    } catch {
      return json({ error: "Could not parse quiz output." }, 502);
    }

    const result = {
      quizTitle: quizData?.quiz_title || `${topic} Quiz`,
      totalMarks: quizData?.total_marks || (quizData?.questions?.length ?? 10) * 2,
      questions: quizData?.questions ?? [],
      cached: false,
    };

    // 4. Cache and update usage
    if (supabaseUrl && supabaseServiceKey) {
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
      fetch(`${supabaseUrl}/rest/v1/ai_cache`, {
        method: "POST",
        headers: { ...dbHeaders, "Prefer": "resolution=merge-duplicates" },
        body: JSON.stringify({
          cache_key: cacheKey,
          feature: "quiz",
          prompt_version: "v1",
          response: result,
          user_id: userId,
          source_id: topic,
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
    console.error("generate-quiz error:", error);
    return json({ error: "Could not generate quiz.", detail: String(error) }, 500);
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
