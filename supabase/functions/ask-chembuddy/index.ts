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
    const mode = String(body.mode ?? "").trim().toLowerCase() || "quick";
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
      mode,
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

    // 8. Build adaptive prompt for Gemini
    const lowerQ = question.toLowerCase();
    const isOrganic = /organic|reaction|mechanism|sn1|sn2|e1|e2|aldol|wittig|diels|electrophil|nucleophil|carbocation|carbanion|stereochem|aromatic|benzene|reagent|synthesis|aspirin|ester/i.test(lowerQ);
    const isPhysical = /physical|thermodynamic|enthalpy|entropy|gibbs|free energy|kinetics|rate law|arrhenius|activation energy|electrochem|nernst|cell potential|quantum|schrodinger|phase rule|equilibrium|clapeyron/i.test(lowerQ);
    const isInorganic = /inorganic|coordination|ligand|crystal field|cft|mot|backbonding|chelate|lanthanide|actinide|metallurgy|organometallic|18 electron|spin state|isomorphism/i.test(lowerQ);
    const isAnalytical = /analytical|titration|buffer|henderson|normality|molarity|molality|ppm|ppb|gravimetr|indicator|chromatography|standard solution/i.test(lowerQ);
    const isSpectroscopy = /spectroscop|nmr|pmr|chemical shift|coupling constant|infrared|ir stretch|uv-vis|beer|lambert|mass spec|fragmentation|spin-spin/i.test(lowerQ);

    let modeInstructions = "";

    if (mode === "2m" || question.includes("[Format as a concise 2-Mark")) {
      modeInstructions = `ANSWER MODE: 2-MARK UNIVERSITY EXAM FORMAT
Format as a high-scoring 2-Mark short university answer:
1. **Definition / Direct Answer**: 1 to 2 crisp, high-yield sentences.
2. **Essential Points**: 2 to 3 concise bullet points with key nuances.
3. **Key Equation / Balanced Reaction**: State the primary governing formula, balanced reaction, or units.
Keep it strictly under 150 words. Do not pad with unnecessary history or lectures.`;
    } else if (mode === "5m" || question.includes("[Format as a structured 5-Mark")) {
      if (isOrganic) {
        modeInstructions = `ANSWER MODE: 5-MARK MSC ORGANIC CHEMISTRY EXAM RUBRIC
Provide a structured 5-Mark MSc university examination answer:
1. **Principle & Definition**: Concise statement and theoretical basis.
2. **Overall Balanced Reaction**: Full stoichiometric reaction with reagents and conditions.
3. **Stepwise Reaction Mechanism**: Electron-pushing steps with curved-arrow movement and key intermediates.
4. **Reaction Conditions & Stereochemistry**: Regioselectivity, stereochemistry, and solvent effects.
5. **Synthetic Applications / Scope**: 2 to 3 real-world laboratory or industrial synthesis examples.`;
      } else if (isPhysical) {
        modeInstructions = `ANSWER MODE: 5-MARK MSC PHYSICAL CHEMISTRY EXAM RUBRIC
Provide a structured 5-Mark MSc university examination answer:
1. **Statement of Law / Definition**: Exact physical chemistry law or principle.
2. **Mathematical Formulation**: Governing equations with all variables and SI units clearly stated.
3. **Derivation / Physical Interpretation**: Stepwise logical progression from fundamentals.
4. **Thermodynamic / Kinetic Significance**: Temperature/pressure dependence and graphical representation notes.
5. **Practical Applications / Solved Illustration**: Direct quantitative application.`;
      } else if (isInorganic) {
        modeInstructions = `ANSWER MODE: 5-MARK MSC INORGANIC CHEMISTRY EXAM RUBRIC
Provide a structured 5-Mark MSc university examination answer:
1. **Definition & Coordination Context**: IUPAC nomenclature, oxidation state, coordination number.
2. **Geometry & Electronic Configuration**: d-electron count, spatial arrangement.
3. **Bonding Model (CFT / MOT)**: Crystal field splitting (Δo / Δt), pairing energy, magnetic moment (μ_eff = √(n(n+2)) BM).
4. **Spectral & Chemical Properties**: d-d transitions, Jahn-Teller distortion, or ligand exchange.
5. **Representative Complexes & Applications**: Industrial catalysts or biological roles.`;
      } else if (isSpectroscopy || isAnalytical) {
        modeInstructions = `ANSWER MODE: 5-MARK MSC SPECTROSCOPY / ANALYTICAL EXAM RUBRIC
Provide a structured 5-Mark MSc university examination answer:
1. **Principle & Fundamental Law**: Selection rules, energy transition, or analytical principle (e.g. Beer-Lambert).
2. **Instrumentation / Transition Mechanism**: Working mechanism or electromagnetic spectrum region.
3. **Characteristic Spectral Values / Peaks**: Diagnostic chemical shifts, absorption frequencies, or m/z values.
4. **Factors Influencing Signals**: Chemical environment, conjugation, solvent effects, or interferents.
5. **Structural Elucidation / Analytical Application**: Exact diagnostic role in determining molecular structure.`;
      } else {
        modeInstructions = `ANSWER MODE: 5-MARK MSC UNIVERSITY EXAM RUBRIC
Provide a structured 5-Mark MSc university examination answer:
1. **Definition & Core Law**
2. **Principle & Governing Formula / Reaction**
3. **Key Characteristics / Mechanism**
4. **Representative Example & Solved Problem / Illustration**
5. **Summary & Synthetic / Analytical Applications**`;
      }
    } else if (mode === "10m" || question.includes("[Format as a comprehensive 10-Mark")) {
      modeInstructions = `ANSWER MODE: 10-MARK MSC COMPREHENSIVE UNIVERSITY EXAM RUBRIC
Provide an exhaustive, authoritative 10-Mark university exam answer:
- **1. Historical Background & Fundamental Theoretical Framework** (2 Marks)
- **2. Detailed Step-by-Step Reaction Mechanism / Mathematical Derivation** (4 Marks)
- **3. Stereochemical Nuances, Orbital Overlap (HOMO/LUMO), or Kinetic/Thermodynamic Factors** (2 Marks)
- **4. Limitations, Competing Pathways, and Industrial / Laboratory Synthesis Applications** (2 Marks)`;
    } else if (mode === "mscconcept" || question.includes("[Explain in Academic MSc Concept Mode")) {
      modeInstructions = `ANSWER MODE: MSC CONCEPT MODE
Focus on deep physical-chemical understanding:
- Molecular orbital explanations (HOMO/LUMO interactions)
- Thermodynamic stability vs kinetic activation (Hammond's postulate, Curtin-Hammett)
- Clear, authoritative chemical intuition without hand-waving.`;
    } else if (mode === "mechanisms" || question.includes("Explain the full stepwise reaction mechanism")) {
      modeInstructions = `ANSWER MODE: STEPWISE REACTION MECHANISM
Provide the full, stepwise organic/inorganic reaction mechanism:
- Step-by-step electron displacement (nucleophilic attack, proton transfer, leaving group departure, rearrangement)
- Structure and stability of all reactive intermediates (carbocation, carbanion, cyclic intermediate, tetrahedral species)
- Driving force (thermodynamics, resonance stabilization, aromaticity, leaving group ability).`;
    } else {
      // DEFAULT QUICK ANSWER MODE
      modeInstructions = `DEFAULT MODE: QUICK & DIRECT ANSWER (⚡)
The student is asking a standard chemistry question.
- Give a fast, direct, smart, and concise answer (2 to 5 clear sentences or clean bullet points).
- DO NOT force artificial headings like "### Definition", "### Principle", "### Mechanism", "### Applications" unless requested.
- Explain cleanly, correctly, and accurately without introductory fluff or repetitive filler.`;
    }

    const systemPrompt = `You are ChemBuddy AI, an intelligent, accurate, and pedagogical Chemistry AI tutor.

${modeInstructions}

CORE OPERATING INSTRUCTIONS:
1. CLEAN CHEMICAL FORMULAS & REACTIONS (CRITICAL):
   - For chemical formulas and reactions, use clean, readable Unicode notation that renders flawlessly:
     * Subscripts: H₂SO₄, H₂O, CO₂, NaOH, CH₃COOH, R-CHO, R-COOH, R-CH₂O⁻, etc.
     * Superscripts and charges: H⁺, OH⁻, Na⁺, Cl⁻, Ca²⁺, SO₄²⁻, O⁻
     * Reaction arrows: → for irreversible, ⇌ for equilibrium, ↑ for gas, ↓ for precipitate.
     * Write mechanism steps naturally and clearly, for example:
       Step 1: R-CHO + OH⁻ ⇌ R-CH(OH)O⁻
       Step 2: R-CH(OH)O⁻ + R-CHO → R-COOH + R-CH₂O⁻ (slow, RDS)
       Step 3: R-COOH + R-CH₂O⁻ → R-COO⁻ + R-CH₂OH (fast)
   - NEVER output internal placeholders or parser tokens such as DISPLAY_MATH_0 or ___DISPLAY_MATH___.
   - NEVER output broken LaTeX command strings in plain text (e.g. DO NOT write \\text{}, \\to, \\rightleftharpoons, or \\frac{} inside narrative text).
   - NEVER output broken LaTeX like \\text\${} or unmatched trailing \$\$.
   - ONLY for complex mathematical derivations or thermodynamics laws on their own line, you may use standard display math:
     \$\$\\Delta G^\\circ = -RT \\ln K\$\$

2. ZERO HALLUCINATIONS:
   - Always answer the exact topic asked. Never substitute buffer solutions, Henderson-Hasselbalch equations, or generic templates for unrelated questions.

${context ? `AVAILABLE STUDY CONTEXT (use as primary factual reference):\n${context}` : ""}`;

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
          temperature: 0.2,
          maxOutputTokens: 1500,
          thinkingConfig: {
            thinkingLevel: "low",
          },
        },
      }
    );

    if (!chatRes.ok || !chatRes.data) {
      return json({ error: "ChemBuddy could not generate an answer right now.", detail: chatRes.errorText }, 502);
    }

    let answer = chatRes.data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    if (!answer) {
      return json({ error: "ChemBuddy produced an empty response." }, 502);
    }

    // Clean any accidental placeholder tokens or broken remnants
    answer = answer.replace(/___?DISPLAY_MATH[0-9₀-₉_]*___?/g, "");
    answer = answer.replace(/DISPLAY_MATH[0-9₀-₉_]+/g, "");

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

    // Speculative Hedging: If key 0 hasn't responded in 650ms, start key 1 in parallel.
    // If neither has answered in 1300ms, start key 2 in parallel.
    for (let i = 1; i < orderedKeys.length; i++) {
      const timer = setTimeout(() => {
        if (!settled) {
          dispatchKey(i);
        }
      }, i * 650);
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
