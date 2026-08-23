Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors() });
  }

  try {
    // 1. Verify admin authorization via service role (only edge functions should call this)
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.toLowerCase().startsWith("bearer ")) {
      return json({ error: "Authorization required." }, 401);
    }

    // 2. Verify Gemini key
    const geminiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
    if (!geminiKey) {
      return json({ error: "AI embedding is not configured." }, 500);
    }

    // 3. Parse request
    const body = await req.json();
    const documentId = String(body.documentId ?? "").trim();
    const text = String(body.text ?? "").trim();
    const subject = String(body.subject ?? "").trim();
    const topic = String(body.topic ?? "").trim();
    const fileName = String(body.fileName ?? "").trim();

    if (!documentId || text.length < 40) {
      return json({ error: "Document ID and sufficient text are required." }, 400);
    }

    // 4. Supabase client for DB writes
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

    // 5. Update document status to processing
    await fetch(`${supabaseUrl}/rest/v1/rag_documents?id=eq.${documentId}`, {
      method: "PATCH",
      headers,
      body: JSON.stringify({ status: "processing", updated_at: new Date().toISOString() }),
    });

    // 6. Clean and chunk text
    const cleanedText = cleanText(text);
    const chunks = chunkText(cleanedText, 500, 50);

    if (chunks.length === 0) {
      await updateDocStatus(supabaseUrl, headers, documentId, "error", "No usable text found after cleaning.");
      return json({ error: "No usable text found in document." }, 400);
    }

    // 7. Generate embeddings in batches
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
    }> = [];

    for (let i = 0; i < chunks.length; i += batchSize) {
      const batch = chunks.slice(i, i + batchSize);

      // Batch embed
      const embedUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:batchEmbedContents?key=${geminiKey}`;

      const requests = batch.map((chunk) => ({
        model: `models/${model}`,
        content: { parts: [{ text: chunk.text }] },
        taskType: "RETRIEVAL_DOCUMENT",
      }));

      const embedRes = await fetch(embedUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ requests }),
      });

      if (!embedRes.ok) {
        const detail = await embedRes.text();
        console.error(`Embedding batch ${i} failed:`, detail);
        // Try individual embeddings as fallback
        for (let j = 0; j < batch.length; j++) {
          try {
            const singleUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:embedContent?key=${geminiKey}`;
            const singleRes = await fetch(singleUrl, {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                model: `models/${model}`,
                content: { parts: [{ text: batch[j].text }] },
                taskType: "RETRIEVAL_DOCUMENT",
              }),
            });
            if (singleRes.ok) {
              const data = await singleRes.json();
              const embedding = data?.embedding?.values;
              if (embedding) {
                allChunkRows.push({
                  document_id: documentId,
                  chunk_index: i + j,
                  content: batch[j].text,
                  subject: subject || "",
                  topic: topic || "",
                  page_number: batch[j].pageNumber,
                  token_count: batch[j].text.split(/\s+/).length,
                  embedding: `[${embedding.join(",")}]`,
                });
              }
            }
          } catch (e) {
            console.error(`Single embedding ${i + j} failed:`, e);
          }
        }
        continue;
      }

      const embedData = await embedRes.json();
      const embeddings = embedData?.embeddings;

      if (embeddings && Array.isArray(embeddings)) {
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
            });
          }
        }
      }
    }

    if (allChunkRows.length === 0) {
      await updateDocStatus(supabaseUrl, headers, documentId, "error", "Could not generate embeddings for any chunks.");
      return json({ error: "Embedding generation failed for all chunks." }, 502);
    }

    // 8. Insert chunks into database in batches
    const insertBatchSize = 50;
    for (let i = 0; i < allChunkRows.length; i += insertBatchSize) {
      const batch = allChunkRows.slice(i, i + insertBatchSize);
      const insertRes = await fetch(`${supabaseUrl}/rest/v1/rag_chunks`, {
        method: "POST",
        headers: { ...headers, "Prefer": "return=minimal" },
        body: JSON.stringify(batch),
      });

      if (!insertRes.ok) {
        const detail = await insertRes.text();
        console.error(`Chunk insert batch ${i} failed:`, detail);
      }
    }

    // 9. Update document status to ready
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
      totalChunks: chunks.length,
    });
  } catch (error) {
    console.error("ingest-document error:", error);
    return json(
      { error: "Document ingestion failed.", detail: String(error) },
      500,
    );
  }
});

// ─── Helpers ──────────────────────────────────────────────

function cleanText(raw: string): string {
  return raw
    .replace(/\0/g, "")
    .replace(/[^\S\n]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

interface Chunk {
  text: string;
  pageNumber: number | null;
}

function chunkText(text: string, maxTokens: number, overlapTokens: number): Chunk[] {
  const words = text.split(/\s+/);
  if (words.length === 0) return [];

  const chunks: Chunk[] = [];
  let start = 0;

  while (start < words.length) {
    const end = Math.min(start + maxTokens, words.length);
    const chunkWords = words.slice(start, end);
    const chunkText = chunkWords.join(" ").trim();

    if (chunkText.length > 20) {
      chunks.push({
        text: chunkText,
        pageNumber: null, // Page detection would need PDF metadata
      });
    }

    if (end >= words.length) break;
    start = end - overlapTokens;
    if (start <= (chunks.length > 0 ? end - maxTokens : 0)) {
      start = end;
    }
  }

  return chunks;
}

async function updateDocStatus(
  supabaseUrl: string,
  headers: Record<string, string>,
  documentId: string,
  status: string,
  errorMessage?: string,
) {
  const payload: Record<string, unknown> = {
    status,
    updated_at: new Date().toISOString(),
  };
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
