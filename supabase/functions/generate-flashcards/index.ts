Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors() });
  }

  try {
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.toLowerCase().startsWith("bearer ")) {
      return json({ error: "Sign in required to generate flashcards." }, 401);
    }

    const geminiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
    if (!geminiKey) {
      return json({ error: "Gemini is not configured on the server." }, 500);
    }

    const body = await req.json();
    const sourceText = String(body.sourceText ?? "").trim();
    const count = Math.min(Math.max(Number(body.count) || 10, 5), 40);
    const topic = String(body.topic ?? "Chemistry").trim() || "Chemistry";

    if (sourceText.length < 40) {
      return json({ error: "Not enough readable text to generate flashcards." }, 400);
    }

    const clipped = sourceText.length > 14000 ? sourceText.slice(0, 14000) : sourceText;
    const prompt = `You are an expert Chemistry professor creating exam-quality flashcards for MSc Chemistry students.

Topic focus: ${topic}

Prioritize important concepts, definitions, mechanisms, named reactions, reagents, reaction conditions, equations, spectroscopy, organic/inorganic/physical/analytical chemistry, exam-relevant facts, important exceptions, and comparisons.

Avoid trivial, duplicate, ambiguous, or unsupported questions. Do not invent chemistry that is not supported by the notes. Keep questions concise.

Create exactly ${count} flashcards from these notes:

${clipped}

Return ONLY valid JSON with this shape:
{"flashcards":[{"question":"...","answer":"...","topic":"${topic}"}]}`;

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-2.0-flash";
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;

    const ai = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.4,
          responseMimeType: "application/json",
        },
      }),
    });

    if (!ai.ok) {
      const detail = await ai.text();
      return json({ error: "Gemini could not generate flashcards right now.", detail }, 502);
    }

    const payload = await ai.json();
    const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    const parsed = parseCards(text);
    if (parsed.length === 0) {
      return json({ error: "The AI response was not valid flashcard JSON." }, 502);
    }

    return json({ flashcards: parsed.slice(0, count) });
  } catch (error) {
    return json({ error: "Could not generate flashcards.", detail: String(error) }, 500);
  }
});

function parseCards(raw) {
  let text = String(raw ?? "").trim();
  const fence = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fence) text = fence[1].trim();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}");
    if (start < 0 || end <= start) return [];
    try {
      data = JSON.parse(text.slice(start, end + 1));
    } catch {
      return [];
    }
  }
  const list = Array.isArray(data?.flashcards) ? data.flashcards : [];
  return list
    .map((item) => ({
      question: String(item?.question ?? "").trim(),
      answer: String(item?.answer ?? "").trim(),
      topic: String(item?.topic ?? "Chemistry").trim() || "Chemistry",
    }))
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
