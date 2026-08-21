# Smart Flashcards backend

This Chem Buddy feature uses **Supabase + an Edge Function**. The Gemini API key never ships in the Flutter app.

## 1. Database

In the Supabase SQL editor, run `supabase/schema.sql` (creates flashcard tables + RLS on top of existing Chem Buddy tables).

## 2. Edge Function

```bash
supabase functions deploy generate-flashcards
supabase secrets set GEMINI_API_KEY=YOUR_GEMINI_KEY
```

Optional: `supabase secrets set GEMINI_MODEL=gemini-2.0-flash`

## 3. Flutter env

Copy `.env.example` to `.env` and set only:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Do **not** add `GEMINI_API_KEY` to `.env`.
