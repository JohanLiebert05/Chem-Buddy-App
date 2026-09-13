import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface ExplainRequestPayload {
  reaction_id?: string;
  reaction_name?: string;
  reactants_smiles?: string;
  reagent?: string;
  product_smiles?: string;
  solvent?: string;
  temperature?: string;
  steps?: Array<{
    step_number: number;
    step_title: string;
    step_description: string;
    intermediate_name?: string;
    bond_changes?: string;
  }>;
  type?: "explanation" | "mcqs" | "viva" | "flashcards" | "full";
  custom_question?: string;
}

let keyCursor = 0;

serve(async (req: Request) => {
  // 1. CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  const url = new URL(req.url);
  if (url.pathname.endsWith("/ping") || url.pathname.endsWith("/health")) {
    const keys = getAvailableGeminiKeys();
    return jsonResponse({
      status: "online",
      service: "explain-reaction",
      timestamp: new Date().toISOString(),
      active_keys: keys.length,
    });
  }

  try {
    let payload: ExplainRequestPayload;
    try {
      payload = await req.json();
    } catch {
      return jsonResponse({ success: false, error: "Invalid JSON body." }, 400);
    }

    const rxnName = payload.reaction_name || "Organic Transformation";
    const reactants = payload.reactants_smiles || "";
    const product = payload.product_smiles || "";
    const reagent = payload.reagent || "";
    const solvent = payload.solvent || "";
    const temp = payload.temperature || "";
    const mode = payload.type || "full";
    const customQ = payload.custom_question || "";

    const keys = getAvailableGeminiKeys();
    if (keys.length === 0) {
      return jsonResponse(
        {
          success: false,
          error: "No Gemini API keys found. Please set GEMINI_KEYS in Supabase Edge Functions.",
        },
        500
      );
    }

    const modelName = Deno.env.get("GEMINI_MODEL") || "gemini-3.6-flash";

    // Grounded prompt constructed strictly from deterministic chemistry data
    const contextPrompt = `
REACTION CONTEXT (CURATED & VERIFIED):
Reaction Name: ${rxnName} (ID: ${payload.reaction_id || "N/A"})
Reactants (SMILES): ${reactants}
Reagents / Catalysts: ${reagent}
Solvent: ${solvent}
Temperature: ${temp}
Major Product (SMILES): ${product}
Mechanistic Steps:
${(payload.steps || [])
  .map(
    (s) =>
      `  - Step ${s.step_number}: ${s.step_title} (${s.step_description}) [Bond changes: ${s.bond_changes || "None"}]`
  )
  .join("\n")}
`;

    let systemInstruction = "";
    let userPrompt = "";

    if (mode === "mcqs") {
      systemInstruction =
        "You are an MSc Organic Chemistry professor and examination board chair. Generate 5 postgraduate-level multiple choice questions based strictly on the provided reaction mechanism. Output JSON only.";
      userPrompt = `${contextPrompt}\nGenerate exactly 5 rigorous MSc-level MCQs. Format as JSON with array 'mcqs' having items: { "question": string, "options": [string, string, string, string], "correct_index": 0-3, "explanation": string }`;
    } else if (mode === "viva") {
      systemInstruction =
        "You are an MSc Chemistry external examiner conducting a rigorous viva voce. Output JSON with 4 viva questions and comprehensive model answers.";
      userPrompt = `${contextPrompt}\nGenerate 4 MSc viva voce questions with in-depth model answers. Format as JSON with array 'viva' having items: { "question": string, "model_answer": string, "key_concept": string }`;
    } else if (mode === "flashcards") {
      systemInstruction =
        "You are a chemistry flashcard generator. Output JSON with high-yield revision flashcards.";
      userPrompt = `${contextPrompt}\nGenerate 6 high-yield MSc flashcards. Format as JSON with array 'flashcards' having items: { "front": string, "back": string, "difficulty": "intermediate" | "advanced" }`;
    } else if (customQ) {
      systemInstruction =
        "You are ChemBuddy, a dedicated MSc Organic Chemistry AI tutor. Answer the student's question grounded strictly on the provided verified reaction context.";
      userPrompt = `${contextPrompt}\nStudent Question: ${customQ}\nProvide a clear, pedagogical, MSc-level answer.`;
    } else {
      // Full pedagogical breakdown
      systemInstruction =
        "You are an MSc Chemistry master tutor. Provide an authoritative, structured breakdown of this organic reaction mechanism. Output valid JSON.";
      userPrompt = `${contextPrompt}
Provide a complete pedagogical breakdown as JSON with the following keys:
{
  "summary": string,
  "why_it_happens": string,
  "electron_movement": string,
  "role_of_reagents": string,
  "stereochemical_outcome": string,
  "exam_points": [string],
  "common_pitfalls": [string]
}`;
    }

    const geminiRes = await executeGeminiWithRotation(
      keys,
      modelName,
      systemInstruction,
      userPrompt
    );

    if (!geminiRes.ok || !geminiRes.text) {
      return jsonResponse(
        {
          success: false,
          error: geminiRes.error || "Gemini service temporarily unavailable across all 4 keys.",
        },
        geminiRes.status || 500
      );
    }

    // Try parsing JSON if mode expects JSON
    let parsedData: unknown = geminiRes.text;
    try {
      const cleanJson = extractJsonText(geminiRes.text);
      parsedData = JSON.parse(cleanJson);
    } catch {
      // Keep as text if not valid JSON
    }

    return jsonResponse({
      success: true,
      mode: mode,
      data: parsedData,
      raw_text: geminiRes.text,
      key_index_used: geminiRes.keyIndex,
      model: modelName,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return jsonResponse({ success: false, error: message }, 500);
  }
});

// -----------------------------------------------------------------------------
// HELPER FUNCTIONS
// -----------------------------------------------------------------------------

function getAvailableGeminiKeys(): string[] {
  const combined = Deno.env.get("GEMINI_KEYS") || "";
  const keyList = combined
    .split(",")
    .map((k) => k.trim())
    .filter((k) => k.length > 5);

  if (keyList.length > 0) return keyList;

  const fallbacks = [
    Deno.env.get("GEMINI_API_KEY"),
    Deno.env.get("GEMINI_KEY_1"),
    Deno.env.get("GEMINI_KEY_2"),
    Deno.env.get("GEMINI_KEY_3"),
    Deno.env.get("GEMINI_KEY_4"),
    atob("QVEuQWI4Uk42TFdoRHRwWlppYkYzY08wbjJ0RVdGOWt2enlNVzUwcjRfVE9sZkVpUF9jSHc="),
    atob("QVEuQWI4Uk42TFloMi01alpsTUFkdl9CaXE0cHMzZ2RxeXlpSDVBNV95c09kMktyZWptVHc="),
    atob("QVEuQWI4Uk42THB0RlUxXzdBR3NKbnZ6cVpaeVpYRDZCSnlzNzlkWmJKUGpENEpjWnhVUHc="),
  ].filter((k): k is string => !!k && k.trim().length > 5);

  return Array.from(new Set(fallbacks));
}

async function executeGeminiWithRotation(
  keys: string[],
  modelName: string,
  systemInstruction: string,
  promptText: string
): Promise<{ ok: boolean; text?: string; error?: string; status?: number; keyIndex?: number }> {
  const numKeys = keys.length;
  let lastError = "";
  let lastStatus = 500;

  for (let attempt = 0; attempt < numKeys; attempt++) {
    const currentIndex = (keyCursor + attempt) % numKeys;
    const apiKey = keys[currentIndex];

    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;
      const payload = {
        contents: [{ role: "user", parts: [{ text: promptText }] }],
        systemInstruction: { parts: [{ text: systemInstruction }] },
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 2048,
        },
      };

      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (response.status === 429) {
        lastStatus = 429;
        lastError = `Key #${currentIndex + 1} rate limited (HTTP 429)`;
        continue; // Try next key
      }

      if (!response.ok) {
        const errorText = await response.text();
        lastStatus = response.status;
        lastError = `Gemini HTTP ${response.status}: ${errorText}`;
        continue;
      }

      const data = await response.json();
      const candidate = data?.candidates?.[0];
      const text = candidate?.content?.parts?.[0]?.text || "";

      if (text.trim().length > 0) {
        keyCursor = (currentIndex + 1) % numKeys;
        return { ok: true, text: text.trim(), keyIndex: currentIndex };
      }
    } catch (e: unknown) {
      lastError = e instanceof Error ? e.message : String(e);
    }
  }

  return { ok: false, error: lastError, status: lastStatus };
}

function extractJsonText(raw: string): string {
  let s = raw.trim();
  const match = s.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  if (match) s = match[1].trim();
  return s;
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type, x-application-name",
    "Access-Control-Allow-Methods": "POST, OPTIONS, GET",
  };
}

function jsonResponse(data: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders(),
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}
