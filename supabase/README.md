# Chem Buddy — Supabase Backend

This project uses **Supabase** for authentication, database, storage, and Edge Functions. API keys for AI (Gemini) never ship in the Flutter app.

## Quick Setup

### 1. Database

Run these SQL files **in order** in the Supabase SQL editor:

```bash
# Step 1: Base schema (attendance, timetable, notes, flashcards)
supabase/schema.sql

# Step 2: Admin, RAG, and vector search
supabase/migrations/002_admin_rag.sql
```

> **Note:** Migration 002 requires the `pgvector` extension. Enable it in your Supabase project under **Database → Extensions → vector**.

### 2. Storage Buckets

Create these storage buckets in the Supabase dashboard (**Storage → New Bucket**):

| Bucket | Public | Purpose |
|--------|--------|---------|
| `documents` | No | Admin-uploaded PDFs for knowledge base |

Storage policies (set via dashboard):
- **documents/SELECT:** Authenticated users can read
- **documents/INSERT:** Only admins (`role = 'admin'` in profiles)
- **documents/DELETE:** Only admins

### 3. Edge Functions

Deploy all three Edge Functions:

```bash
# Smart Flashcard generation (existing)
supabase functions deploy generate-flashcards

# Ask ChemBuddy RAG pipeline (new)
supabase functions deploy ask-chembuddy

# Document ingestion pipeline (new)
supabase functions deploy ingest-document
```

### 4. Secrets

Set these secrets (never put them in Flutter):

```bash
supabase secrets set GEMINI_API_KEY=your_gemini_key
```

Optional overrides:
```bash
supabase secrets set GEMINI_MODEL=gemini-2.0-flash
supabase secrets set GEMINI_EMBEDDING_MODEL=text-embedding-004
```

### 5. Flutter Environment

Copy `.env.example` to `.env` and set only:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

**Never** add `GEMINI_API_KEY` to `.env`.

### 6. Create First Admin

After running the migrations, manually promote a user to admin:

```sql
UPDATE public.profiles
SET role = 'admin'
WHERE register_number = 'YOUR_REGISTER_NUMBER';
```

Or insert a seeded admin during setup (see migration 002).

---

## Architecture

```
Flutter App
  → supabase_flutter (Auth + DB + Storage + Functions)
  → Hive (offline cache)

Supabase
  ├── Auth (register number → synthetic email mapping)
  ├── PostgreSQL + pgvector (profiles, rag_chunks, etc.)
  ├── Row Level Security (student/admin policies)
  ├── Storage (documents bucket)
  └── Edge Functions
      ├── generate-flashcards (existing, Gemini flash)
      ├── ask-chembuddy (RAG: embed question → vector search → Gemini answer)
      └── ingest-document (chunk text → batch embed → store vectors)
```

## Edge Functions Detail

### generate-flashcards
- **Input:** `{ sourceText, count, topic }`
- **Output:** `{ flashcards: [{ question, answer, topic }] }`
- **Auth:** Requires user JWT

### ask-chembuddy
- **Input:** `{ question, subject?, history? }`
- **Output:** `{ answer, sources: [{ documentTitle, fileName, subject, pageNumber, similarity }], hasContext, chunksUsed }`
- **Auth:** Requires user JWT
- **Flow:** Question → Gemini embedding → pgvector similarity search → context assembly → Gemini chat generation

### ingest-document
- **Input:** `{ documentId, text, subject?, topic?, fileName? }`
- **Output:** `{ success, chunksCreated, totalChunks }`
- **Auth:** Requires user JWT (admin only via RLS)
- **Flow:** Clean text → chunk (500 tokens, 50 overlap) → batch embed → store in rag_chunks

## Tables

| Table | RLS | Notes |
|-------|-----|-------|
| `profiles` | Own + Admin read all | Register number, role |
| `subjects` | Own only | User's chemistry subjects |
| `attendance_records` | Own only | Daily marks |
| `timetable_slots` | Own only | Weekly schedule |
| `academic_events` | Own only | Tests, assignments |
| `notes` | Own only | Quick notes |
| `flashcard_sets` | Own only | AI-generated sets |
| `flashcards` | Own only | Individual cards |
| `flashcard_attempts` | Own only | Study responses |
| `study_sessions` | Own only | Study progress |
| `announcements` | Students read published, admins all | Admin notices |
| `rag_documents` | Students read ready, admins all | Knowledge base files |
| `rag_chunks` | Students read (ready docs), admins all | Vector embeddings |
| `ai_conversations` | Own only | Chat history |
| `ai_messages` | Own only | Chat messages |
