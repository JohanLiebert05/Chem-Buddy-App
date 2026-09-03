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

    // 4. Get Supabase client for DB operations
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      return json({ error: "Database is not configured." }, 500);
    }

    // 5. Generate embedding for the question
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

    if (!embeddingRes.ok) {
      const detail = await embeddingRes.text();
      return json({ error: "Could not process your question.", detail }, 502);
    }

    const embeddingData = await embeddingRes.json();
    const embedding = embeddingData?.embedding?.values;

    if (!embedding || !Array.isArray(embedding)) {
      return json({ error: "Could not generate question embedding." }, 502);
    }

    // 6. Search for relevant chunks via RPC
    const matchRes = await fetch(`${supabaseUrl}/rest/v1/rpc/match_rag_chunks`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${supabaseServiceKey}`,
        "apikey": supabaseServiceKey,
      },
      body: JSON.stringify({
        query_embedding: `[${embedding.join(",")}]`,
        match_count: 6,
        match_threshold: 0.3,
        filter_subject: subject || null,
      }),
    });

    if (!matchRes.ok) {
      const detail = await matchRes.text();
      console.error("match_rag_chunks error:", detail);
      // Fall back to answering without context
    }

    const chunks = matchRes.ok ? (await matchRes.json()) as Array<{
      id: string;
      content: string;
      subject: string;
      topic: string;
      page_number: number;
      document_title: string;
      file_name: string;
      similarity: number;
    }> : [];

    // 7. Build context and prompt
    let context = "";
    const sources: Array<{
      documentTitle: string;
      fileName: string;
      subject: string;
      topic: string;
      pageNumber: number;
      similarity: number;
    }> = [];

    // Prioritize user's uploaded document if provided
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

    // 8. Build conversation for Gemini
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
    if (conversationHistory && conversationHistory.length > 0) {
      for (const msg of conversationHistory.slice(-6)) {
        contents.push({
          role: msg.role === "user" ? "user" : "model",
          parts: [{ text: msg.content }],
        });
      }
    }

    // Add current question
    contents.push({
      role: "user",
      parts: [{ text: question }],
    });

    // 9. Generate answer with Gemini
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

    // 10. Return answer with sources
    return json({
      answer,
      sources: sources.length > 0 ? sources : [],
      hasContext: chunks.length > 0,
      chunksUsed: chunks.length,
    });
  } catch (error) {
    console.error("ask-chembuddy error:", error);
    return json(
      { error: "Could not process your question.", detail: String(error) },
      500,
    );
  }
});

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
