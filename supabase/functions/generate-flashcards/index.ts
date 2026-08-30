Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors() });
  }

  try {
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.toLowerCase().startsWith("bearer ")) {
      return json({ error: "Authorization required to generate flashcards." }, 401);
    }

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

    // Smart chunking / truncation to 12,000 characters to prevent input token overflow
    const clipped = sourceText.length > 12000 ? sourceText.slice(0, 12000) : sourceText;

    const prompt = `You are an expert MSc Chemistry academic tutor creating rigorous, exam-quality active-recall flashcards based strictly on the uploaded document.

Target Subject/Document: ${topic}

CRITICAL RULES:
1. QUESTION FORMAT: Formulate standalone, high-yield conceptual interrogative questions (e.g., reaction mechanisms, stereochemistry, regioselectivity, rate laws, analytical parameters, instrumentation, and thermodynamic principles).
2. FORBIDDEN: NEVER quote verbatim snippets with trailing ellipses (e.g., NEVER write 'Explain the following point: "..."' or 'What does the document state regarding "..."'). Every question must be a complete, standalone question.
3. ANSWER FORMAT: Provide accurate, comprehensive explanations using clean chemical equations and inline LaTeX notation where applicable.
4. KEY TERMS: For each card, provide 3 to 5 mandatory chemical concepts or keywords required for a complete answer.
5. GROUNDING: You MUST generate all flashcards EXCLUSIVELY and STRICTLY from the provided Study Notes below. Do not pull in generic unrelated topics.
6. Generate exactly ${count} distinct flashcards.

Study Notes:
${clipped}`;

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-2.0-flash";
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;

    const requestPayload = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.3,
        maxOutputTokens: 8192,
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: {
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
                  topic: { type: "STRING", description: "Chemistry sub-discipline or specific topic" }
                },
                required: ["question", "answer", "key_terms", "topic"]
              }
            }
          },
          required: ["flashcards"]
        }
      }
    };

    // 2. Exponential backoff retry loop for network resilience (handling 429, 503, 500)
    let aiResponse = null;
    let lastErrorDetail = "";
    let lastStatusCode = 500;

    for (let attempt = 0; attempt <= 2; attempt++) {
      if (attempt > 0) {
        // Wait 1s, then 2s before retry
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
          // If client error other than 429 (Rate Limit), don't retry blindly
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

    // 3. Inspect finishReason and response safety
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

    return json({ flashcards: parsed.slice(0, count) });
  } catch (error) {
    console.error("Unhandled error in generate-flashcards:", error);
    return json({ error: "Could not generate flashcards.", detail: String(error) }, 500);
  }
});

function parseCards(raw, defaultTopic = "Chemistry") {
  let text = String(raw ?? "").trim();
  
  // Clean / strip markdown code fence blocks (```json ... ``` or ``` ...)
  const fence = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fence) {
    text = fence[1].trim();
  }

  let data = null;
  try {
    data = JSON.parse(text);
  } catch {
    // Attempt robust substring extraction if surrounding noise exists
    const startObj = text.indexOf("{");
    const endObj = text.lastIndexOf("}");
    if (startObj >= 0 && endObj > startObj) {
      try {
        data = JSON.parse(text.slice(startObj, endObj + 1));
      } catch (_) {}
    }
    
    // Also try array matching if root was an array
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
    .map((item) => {
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
    .filter((item) => item.question.length > 3 && item.answer.length > 1);
}

function cors() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors(), "Content-Type": "application/json" },
  });
}
