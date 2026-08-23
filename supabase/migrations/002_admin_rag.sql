-- ============================================================
-- Chem Buddy — Migration 002: Admin, RAG, and Vector Search
-- Run this in the Supabase SQL editor AFTER schema.sql.
-- ============================================================

-- 0. Enable pgvector extension for embeddings
create extension if not exists vector with schema extensions;

-- ============================================================
-- 1. PROFILES — add register_number for college auth
-- ============================================================
alter table public.profiles
  add column if not exists register_number text unique;

-- Index for fast register-number lookups
create index if not exists idx_profiles_register_number
  on public.profiles (register_number);

-- ============================================================
-- 2. ANNOUNCEMENTS — admin-published notices for students
-- ============================================================
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  created_by uuid not null references auth.users (id) on delete cascade,
  published boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.announcements enable row level security;

-- Students can only read published announcements
create policy "students read published announcements"
  on public.announcements for select
  using (published = true);

-- Admins can do everything
create policy "admins manage announcements"
  on public.announcements for all
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- ============================================================
-- 3. RAG DOCUMENTS — admin-uploaded knowledge base source files
-- ============================================================
create table if not exists public.rag_documents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  file_name text not null,
  subject text,
  storage_path text,
  file_size bigint default 0,
  status text default 'pending' check (status in ('pending', 'processing', 'ready', 'error')),
  error_message text,
  chunk_count int default 0,
  uploaded_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.rag_documents enable row level security;

-- Students can read ready documents metadata (not the raw content)
create policy "students read ready rag documents"
  on public.rag_documents for select
  using (status = 'ready');

-- Admins manage all
create policy "admins manage rag documents"
  on public.rag_documents for all
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- ============================================================
-- 4. RAG CHUNKS — embedded document segments for vector search
-- ============================================================
create table if not exists public.rag_chunks (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.rag_documents (id) on delete cascade,
  chunk_index int not null,
  content text not null,
  subject text,
  topic text,
  page_number int,
  token_count int default 0,
  embedding extensions.vector(768),
  created_at timestamptz default now()
);

alter table public.rag_chunks enable row level security;

-- Students can read chunks from ready documents (needed for vector search RPC)
create policy "students read rag chunks"
  on public.rag_chunks for select
  using (
    exists (
      select 1 from public.rag_documents
      where rag_documents.id = rag_chunks.document_id
        and rag_documents.status = 'ready'
    )
  );

-- Admins manage all
create policy "admins manage rag chunks"
  on public.rag_chunks for all
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- Performance index on embedding for similarity search
create index if not exists idx_rag_chunks_embedding
  on public.rag_chunks using ivfflat (embedding extensions.vector_cosine_ops)
  with (lists = 100);

-- Index for filtering by document
create index if not exists idx_rag_chunks_document_id
  on public.rag_chunks (document_id);

-- ============================================================
-- 5. AI CONVERSATIONS — student chat history with Ask ChemBuddy
-- ============================================================
create table if not exists public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text default 'New conversation',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.ai_conversations enable row level security;

create policy "own conversations"
  on public.ai_conversations for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================
-- 6. AI MESSAGES — individual messages in conversations
-- ============================================================
create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.ai_conversations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  sources jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

alter table public.ai_messages enable row level security;

create policy "own messages"
  on public.ai_messages for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================
-- 7. ADMIN RLS — let admins read all profiles for management
-- ============================================================

-- Drop the old restrictive policy and replace with admin-aware one
drop policy if exists "own profiles" on public.profiles;

create policy "own or admin profiles"
  on public.profiles for select
  using (
    auth.uid() = id
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy "own profiles insert"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "own profiles update"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "own profiles delete"
  on public.profiles for delete
  using (auth.uid() = id);

-- Admin can update any profile (e.g., reset password flag, role management)
create policy "admin update profiles"
  on public.profiles for update
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- ============================================================
-- 8. VECTOR SEARCH RPC — secure similarity search function
-- ============================================================
create or replace function public.match_rag_chunks(
  query_embedding extensions.vector(768),
  match_count int default 5,
  match_threshold float default 0.3,
  filter_subject text default null
)
returns table (
  id uuid,
  document_id uuid,
  content text,
  subject text,
  topic text,
  page_number int,
  document_title text,
  file_name text,
  similarity float
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    c.id,
    c.document_id,
    c.content,
    c.subject,
    c.topic,
    c.page_number,
    d.title as document_title,
    d.file_name,
    1 - (c.embedding <=> query_embedding) as similarity
  from public.rag_chunks c
  join public.rag_documents d on d.id = c.document_id
  where d.status = 'ready'
    and (filter_subject is null or c.subject ilike filter_subject)
    and 1 - (c.embedding <=> query_embedding) > match_threshold
  order by c.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- ============================================================
-- 9. HELPER — function to check if current user is admin
-- ============================================================
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ============================================================
-- 10. AUTO-CREATE PROFILE on signup
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.email,
    'student'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- Create trigger only if not exists
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- 11. STORAGE BUCKETS (run via Supabase Dashboard or API)
-- These SQL statements document the intended bucket setup.
-- Actual bucket creation must be done via Supabase Storage API.
-- ============================================================
-- Bucket: documents (admin uploads, private)
-- Bucket: rag (processed chunks metadata, private)

-- Storage policies are set via the Supabase dashboard:
-- documents bucket:
--   SELECT: authenticated users can read
--   INSERT: only admins (role = 'admin' in profiles)
--   DELETE: only admins
-- rag bucket:
--   SELECT: only service role (used by edge functions)
--   INSERT: only service role
