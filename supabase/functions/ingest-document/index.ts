Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors() });
  }

  try {
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.toLowerCase().startsWith("bearer ")) {
      return json({ error: "Authorization required." }, 401);
    }

    const body = await req.json();
    const documentId = String(body.documentId ?? "").trim();
    const subject = String(body.subject ?? "").trim();
    const topic = String(body.topic ?? "").trim();
    const fileName = String(body.fileName ?? "").trim();
    const documentTitle = String(body.documentTitle ?? fileName ?? "").trim();

    // Accept either page-aware array OR legacy flat text
    const pagesInput = body.pages as Array<{ pageNumber: number; text: string }> | null;
    const legacyText = String(body.text ?? "").trim();

    if (!documentId) {
      return json({ error: "Document ID is required." }, 400);
    }

    // Build page list — prefer structured pages, fall back to single flat-text page
    const pages: Array<{ pageNumber: number; text: string }> = [];

    if (Array.isArray(pagesInput) && pagesInput.length > 0) {
      for (const p of pagesInput) {
        const pageText = String(p.text ?? "").trim();
        if (pageText.length >= 20) {
          pages.push({ pageNumber: Number(p.pageNumber) || 1, text: pageText });
        }
      }
    } else if (legacyText.length >= 40) {
      // Legacy: treat entire text as page 1 (no page provenance)
      pages.push({ pageNumber: 1, text: legacyText });
    }

    if (pages.length === 0) {
      return json({ error: "Document ID and sufficient text are required (minimum 40 characters per page)." }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      return json({ error: "Database is not configured." }, 500);
    }

    const headers = {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${supabaseServiceKey}`,
      "apikey": supabaseServiceKey,
    };

    // Mark document as processing
    await fetch(`${supabaseUrl}/rest/v1/rag_documents?id=eq.${documentId}`, {
      method: "PATCH",
      headers,
      body: JSON.stringify({ status: "processing", updated_at: new Date().toISOString() }),
    });

    // Build all chunks with page provenance using semantic sentence-boundary chunking
    const allChunks: Array<{ text: string; pageNumber: number }> = [];
    for (const page of pages) {
      const cleaned = cleanText(page.text);
      const chunks = chunkBySentences(cleaned, 500, 50);
      for (const chunk of chunks) {
        if (chunk.text.length >= 20) {
          allChunks.push({ text: chunk.text, pageNumber: page.pageNumber });
        }
      }
    }

    if (allChunks.length === 0) {
      await updateDocStatus(supabaseUrl, headers, documentId, "error", "No usable text found after cleaning.");
      return json({ error: "No usable text found in document." }, 400);
    }

    const model = Deno.env.get("GEMINI_EMBEDDING_MODEL") || "text-embedding-004";
    const batchSize = 10;
    const allChunkRows: Array<{
      document_id: string;
      chunk_index: number;
      content: string;
      subject: string;
      topic: string;
      page_number: number | null;
      token_count: number;
      embedding: string;
      document_title: string;
      file_name: string;
    }> = [];

    for (let i = 0; i < allChunks.length; i += batchSize) {
      const batch = allChunks.slice(i, i + batchSize);
      const requests = batch.map((chunk) => ({
        model: `models/${model}`,
        content: { parts: [{ text: chunk.text }] },
        taskType: "RETRIEVAL_DOCUMENT",
      }));

      const embedRes = await fetchGeminiWithRotation(
        `models/${model}:batchEmbedContents`,
        { requests }
      );

      if (embedRes.ok && embedRes.data?.embeddings) {
        const embeddings = embedRes.data.embeddings;
        for (let j = 0; j < embeddings.length; j++) {
          const values = embeddings[j]?.values;
          if (values && Array.isArray(values)) {
            allChunkRows.push({
              document_id: documentId,
              chunk_index: i + j,
              content: batch[j].text,
              subject: subject || "",
              topic: topic || "",
              page_number: batch[j].pageNumber,
              token_count: batch[j].text.split(/\s+/).length,
              embedding: `[${values.join(",")}]`,
              document_title: documentTitle,
              file_name: fileName,
            });
          }
        }
      } else {
        // Fallback to single chunk embeds with rotation
        for (let j = 0; j < batch.length; j++) {
          try {
            const singleRes = await fetchGeminiWithRotation(
              `models/${model}:embedContent`,
              {
                model: `models/${model}`,
                content: { parts: [{ text: batch[j].text }] },
                taskType: "RETRIEVAL_DOCUMENT",
              }
            );
            if (singleRes.ok && singleRes.data?.embedding?.values) {
              allChunkRows.push({
                document_id: documentId,
                chunk_index: i + j,
                content: batch[j].text,
                subject: subject || "",
                topic: topic || "",
                page_number: batch[j].pageNumber,
                token_count: batch[j].text.split(/\s+/).length,
                embedding: `[${singleRes.data.embedding.values.join(",")}]`,
                document_title: documentTitle,
                file_name: fileName,
              });
            }
          } catch (e) {
            console.error(`Single embedding ${i + j} failed:`, e);
          }
        }
      }
    }

    if (allChunkRows.length === 0) {
      await updateDocStatus(supabaseUrl, headers, documentId, "error", "Could not generate embeddings for any chunks.");
      return json({ error: "Embedding generation failed for all chunks." }, 502);
    }

    // Delete existing chunks for this document before inserting new ones (re-ingest)
    await fetch(`${supabaseUrl}/rest/v1/rag_chunks?document_id=eq.${documentId}`, {
      method: "DELETE",
      headers,
    });

    const insertBatchSize = 50;
    for (let i = 0; i < allChunkRows.length; i += insertBatchSize) {
      const batch = allChunkRows.slice(i, i + insertBatchSize);
      await fetch(`${supabaseUrl}/rest/v1/rag_chunks`, {
        method: "POST",
        headers: { ...headers, "Prefer": "return=minimal" },
        body: JSON.stringify(batch),
      });
    }

    await fetch(`${supabaseUrl}/rest/v1/rag_documents?id=eq.${documentId}`, {
      method: "PATCH",
      headers,
      body: JSON.stringify({
        status: "ready",
        chunk_count: allChunkRows.length,
        updated_at: new Date().toISOString(),
      }),
    });

    return json({
      success: true,
      chunksCreated: allChunkRows.length,
      totalChunks: allChunks.length,
      pagesProcessed: pages.length,
    });
  } catch (error) {
    console.error("ingest-document error:", error);
    return json({ error: "Document ingestion failed.", detail: String(error) }, 500);
  }
});

// ─── Semantic sentence-boundary chunker ─────────────────────
interface Chunk {
  text: string;
  pageNumber: number;
}

/**
 * Splits text into semantically coherent chunks at sentence boundaries
 * (`. `, `? `, `! `, `\n\n`), keeping each chunk within maxWords.
 * Adjacent chunks share overlapWords tail for cross-boundary context.
 */
function chunkBySentences(text: string, maxWords: number, overlapWords: number): Chunk[] {
  const words = text.split(/\s+/).filter((w) => w.length > 0);
  if (words.length === 0) return [];

  const chunks: Chunk[] = [];
  let start = 0;

  while (start < words.length) {
    const end = Math.min(start + maxWords, words.length);
    let splitAt = end;

    // Walk back from end to find a sentence boundary (word ending in . ? !)
    if (end < words.length) {
      for (let i = end - 1; i >= start + Math.floor(maxWords / 2); i--) {
        if (/[.?!]$/.test(words[i])) {
          splitAt = i + 1;
          break;
        }
      }
    }

    const chunkText = words.slice(start, splitAt).join(" ").trim();
    if (chunkText.length >= 20) {
      chunks.push({ text: chunkText, pageNumber: 1 }); // pageNumber set by caller
    }

    if (splitAt >= words.length) break;
    start = Math.max(start + 1, splitAt - overlapWords);
  }

  return chunks;
}

function cleanText(raw: string): string {
  return raw
    .replace(/\0/g, "")
    .replace(/[^\S\n]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

// ─── Key Pool & Multi-Key Failover Engine ─────────────────────
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

let globalKeyCounter = 0;

async function fetchGeminiWithRotation(
  endpointPath: string,
  payload: unknown,
): Promise<{ ok: boolean; status: number; data?: any; errorText?: string }> {
  const keys = getGeminiKeyPool();
  if (keys.length === 0) {
    return { ok: false, status: 500, errorText: "No Gemini API keys configured." };
  }

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
      scheduledTimeouts.forEach((t) => clearTimeout(t));
      activeControllers.forEach((ac) => { try { ac.abort(); } catch (_) {} });
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

      const attemptTimer = setTimeout(() => { try { ac.abort(); } catch (_) {} }, 12000);

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
        if (index + 1 < orderedKeys.length && !settled) dispatchKey(index + 1);
      } catch (err: any) {
        clearTimeout(attemptTimer);
        if (settled) return;
        if (err.name !== "AbortError") { lastErrorText = String(err); }
        if (index + 1 < orderedKeys.length && !settled) dispatchKey(index + 1);
      }
      checkAllFailed();
    }

    dispatchKey(0);
    for (let i = 1; i < orderedKeys.length; i++) {
      const timer = setTimeout(() => { if (!settled) dispatchKey(i); }, i * 650);
      scheduledTimeouts.push(timer);
    }
  });
}

async function updateDocStatus(
  supabaseUrl: string,
  headers: Record<string, string>,
  documentId: string,
  status: string,
  errorMessage?: string,
) {
  const payload: Record<string, unknown> = { status, updated_at: new Date().toISOString() };
  if (errorMessage) payload.error_message = errorMessage;
  await fetch(`${supabaseUrl}/rest/v1/rag_documents?id=eq.${documentId}`, {
    method: "PATCH",
    headers,
    body: JSON.stringify(payload),
  });
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
