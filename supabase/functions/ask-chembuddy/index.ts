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

    // 2. Verify Gemini key
    const geminiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
    if (!geminiKey) {
      return json({ error: "AI is not configured on the server." }, 500);
    }

    // 3. Parse request
    const body = await req.json();
    const question = String(body.question ?? "").trim();
    const subject = body.subject as string | null;
    const documentText = body.document_text as string | null;
    const documentName = (body.document_name as string | null) || "Uploaded PDF";
    const conversationHistory = body.history as Array<{ role: string; content: string }> | null;

    if (question.length < 3) {
      return json({ error: "Please ask a more specific question." }, 400);
    }

    // 4. Supabase credentials
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

    // 5. Check AI Usage Limits (if user identified)
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

    // 6. Check AI Response Cache
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

    // 7. Generate embedding for RAG search
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
      const model = Deno.env.get("GEMINI_EMBEDDING_MODEL") || "text-embedding-004";
      const embeddingUrl =
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:embedContent?key=${geminiKey}`;

      const embeddingRes = await fetch(embeddingUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: `models/${model}`,
          content: { parts: [{ text: question }] },
          taskType: "RETRIEVAL_QUERY",
        }),
      });

      if (embeddingRes.ok) {
        const embeddingData = await embeddingRes.json();
        const embedding = embeddingData?.embedding?.values;

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

    // 8. Build context and sources
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

    // 9. Build conversation for Gemini
    const systemPrompt = `You are ChemBuddy AI, an expert Chemistry tutor for MSc Chemistry students.

RULES:
- When [USER STUDY MATERIAL] is provided, prioritize it as your primary reference and explicitly answer from "${documentName}".
- MATHEMATICAL & CHEMICAL FORMULAS: Always format equations and formulas in standard LaTeX wrapped in single dollar signs ($...$) for inline math (e.g. "$K_w = [H_3O^+][OH^-] = 1.0 \\times 10^{-14}$", "$\\text{pH} = \\text{p}K_a + \\log\\frac{[\\text{A}^-]}{[\\text{HA}]}$", "$\\Delta G = \\Delta H - T\\Delta S$") or double dollar signs ($$...$$ on its own line) for standalone display equations.
- NEVER leave naked LaTeX commands without dollar signs (do NOT write "\\frac" or "\\times" without wrapping in $...$).
- NEVER use code-style variables with underscores in prose or tables (write "$\\Delta\\rho$", "v_t", or "Δρ", not "delta_rho").
- NEVER invent textbook facts, chemical formulas, references, or citations.
- Give concise, exam-focused explanations suitable for MSc Chemistry students.
- Use proper chemical notation and formatting.
- If the question is completely outside chemistry/academics, politely redirect.

When explaining concepts, use clear structure:
- Use headings (## or ###) for major topics
- Use bullet points for lists
- Use tables when comparing items
- Use bold for key terms
- Use numbered steps for processes
- Keep paragraphs concise

${context ? `AVAILABLE STUDY CONTEXT:\n${context}` : "Answer from your chemistry expertise but clearly indicate this is general knowledge, not from specific course materials."}`;

    const contents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

    // Add conversation history if provided
    // History already excludes the current question on the client.
    // Skip a trailing duplicate user turn if an older client still sent it.
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

    // 10. Generate answer with Gemini
    const chatModel = Deno.env.get("GEMINI_MODEL") || "gemini-2.0-flash";
    const chatUrl =
      `https://generativelanguage.googleapis.com/v1beta/models/${chatModel}:generateContent?key=${geminiKey}`;

    const chatRes = await fetch(chatUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemPrompt }] },
        contents,
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 2048,
        },
      }),
    });

    if (!chatRes.ok) {
      const detail = await chatRes.text();
      return json({ error: "ChemBuddy could not generate an answer right now.", detail }, 502);
    }

    const chatPayload = await chatRes.json();
    const answer =
      chatPayload?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

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

    // 11. Write to Cache & Increment Usage Asynchronously
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
