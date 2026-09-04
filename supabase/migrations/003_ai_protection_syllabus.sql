-- =============================================================================
-- Migration: 003_ai_protection_syllabus.sql
-- Description: AI usage protection, caching, app config, multi-university
--              syllabus, PYQ prediction sessions, and topic mastery tracking.
-- Created: 2026-09-04
-- =============================================================================


-- =============================================================================
-- SECTION 1: AI USAGE TABLE
-- Per-user, per-day request tracking to enforce daily limits.
-- =============================================================================

-- Ensure profile role exists before policies evaluate it
alter table public.profiles
  add column if not exists role text default 'student';

-- Security definer helper to check admin role without RLS infinite recursion
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    (select role = 'admin' from public.profiles where id = auth.uid()),
    false
  );
$$;

-- Fix potential recursion on profiles table policies
drop policy if exists "own or admin profiles" on public.profiles;
drop policy if exists "admin update profiles" on public.profiles;

create policy "own or admin profiles"
  on public.profiles for select
  using (auth.uid() = id or public.is_admin());

create policy "admin update profiles"
  on public.profiles for update
  using (public.is_admin())
  with check (public.is_admin());

-- Table: ai_usage -- per-user daily AI request tracking
create table if not exists public.ai_usage (
  id               uuid        primary key default gen_random_uuid(),
  user_id          uuid        not null references auth.users(id) on delete cascade,
  date             date        not null default current_date,
  request_count    int         default 0,
  input_tokens     int         default 0,
  output_tokens    int         default 0,
  last_request_at  timestamptz default now(),
  unique(user_id, date)
);

alter table public.ai_usage enable row level security;

-- Users can only read/write their own usage rows
drop policy if exists "own ai usage" on public.ai_usage;
create policy "own ai usage" on public.ai_usage
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists idx_ai_usage_user_date on public.ai_usage(user_id, date);


-- =============================================================================
-- SECTION 2: AI CACHE TABLE
-- Deduplicates identical AI prompts across users, respects TTL.
-- =============================================================================

create table if not exists public.ai_cache (
  cache_key      text        primary key,
  feature        text        not null,           -- 'flashcards','quiz','summary','chat','predict_questions'
  prompt_version text        not null default 'v1',
  response       jsonb       not null,
  user_id        uuid        references auth.users(id) on delete set null,  -- null = shared/global
  source_id      text,                            -- doc_id, topic, etc.
  hit_count      int         default 0,
  created_at     timestamptz default now(),
  expires_at     timestamptz                      -- null = never expires
);

alter table public.ai_cache enable row level security;

-- Any authenticated user can read cached results
drop policy if exists "read ai cache" on public.ai_cache;
create policy "read ai cache" on public.ai_cache
  for select using (true);

-- Only authenticated users (via Edge Functions acting on their behalf) can insert
drop policy if exists "service write ai cache" on public.ai_cache;
create policy "service write ai cache" on public.ai_cache
  for insert with check (auth.uid() is not null);

-- Allow cache updates (hit_count increment, expiry refresh) by Edge Functions
drop policy if exists "service update ai cache" on public.ai_cache;
create policy "service update ai cache" on public.ai_cache
  for update using (true);

create index if not exists idx_ai_cache_feature  on public.ai_cache(feature);
create index if not exists idx_ai_cache_expires  on public.ai_cache(expires_at) where expires_at is not null;


-- =============================================================================
-- SECTION 3: APP CONFIG TABLE
-- Runtime-tunable settings for AI limits and model selection.
-- =============================================================================

create table if not exists public.app_config (
  key         text        primary key,
  value       text        not null,
  description text,
  updated_at  timestamptz default now()
);

alter table public.app_config enable row level security;

-- All users can read config (limits, model names, etc.)
drop policy if exists "anyone read config" on public.app_config;
create policy "anyone read config" on public.app_config
  for select using (true);

-- Only admins can insert/update/delete config entries
drop policy if exists "admins write config" on public.app_config;
create policy "admins write config" on public.app_config
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- Seed default config values; safe to re-run (on conflict do nothing)
insert into public.app_config(key, value, description) values
  ('ai_daily_limit_student', '20',               'Max AI requests per student per day'),
  ('ai_daily_limit_admin',   '999',              'Max AI requests per admin per day'),
  ('gemini_model_default',   'gemini-2.0-flash', 'Default Gemini model for all tasks'),
  ('gemini_model_heavy',     'gemini-2.0-flash', 'Model for heavy reasoning tasks'),
  ('ai_cache_ttl_hours',     '168',              'Cache TTL in hours (default 7 days)')
on conflict(key) do nothing;


-- =============================================================================
-- SECTION 4: MULTI-UNIVERSITY SYLLABUS TABLES
-- Hierarchical structure: University -> Subject -> Unit -> Topic
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 4a. Universities / institutions
-- ----------------------------------------------------------------------------
create table if not exists public.universities (
  id         uuid    primary key default gen_random_uuid(),
  name       text    not null unique,
  short_name text,
  state      text,
  country    text    default 'India',
  is_active  boolean default true,
  created_at timestamptz default now()
);

alter table public.universities enable row level security;

drop policy if exists "read universities" on public.universities;
create policy "read universities" on public.universities
  for select using (true);

drop policy if exists "admins manage universities" on public.universities;
create policy "admins manage universities" on public.universities
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- Seed common Indian universities for MSc Chemistry
-- on conflict (name) do nothing makes this idempotent across re-runs
insert into public.universities(name, short_name, state) values
  ('General MSc Chemistry (Common Syllabus)', 'GENERAL',  'All India'),
  ('University of Mumbai',                    'MU',        'Maharashtra'),
  ('University of Delhi',                     'DU',        'Delhi'),
  ('Bangalore University',                    'BU',        'Karnataka'),
  ('University of Pune (SPPU)',               'SPPU',      'Maharashtra'),
  ('Osmania University',                      'OU',        'Telangana'),
  ('Madras University',                       'MU-TN',     'Tamil Nadu'),
  ('Calcutta University',                     'CU',        'West Bengal')
on conflict (name) do nothing;

-- ----------------------------------------------------------------------------
-- 4b. Syllabus subjects (linked to a university)
-- ----------------------------------------------------------------------------
create table if not exists public.syllabus_subjects (
  id            uuid    primary key default gen_random_uuid(),
  university_id uuid    references public.universities(id) on delete cascade,
  name          text    not null,
  code          text,
  semester      int     not null default 1,
  description   text,
  sort_order    int     default 0,
  is_active     boolean default true,
  created_at    timestamptz default now()
);

alter table public.syllabus_subjects enable row level security;

drop policy if exists "read syllabus subjects" on public.syllabus_subjects;
create policy "read syllabus subjects" on public.syllabus_subjects
  for select using (true);

drop policy if exists "admins manage syllabus subjects" on public.syllabus_subjects;
create policy "admins manage syllabus subjects" on public.syllabus_subjects
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- Efficient lookup by university + semester for dropdown population
create index if not exists idx_syllabus_subjects_univ
  on public.syllabus_subjects(university_id, semester);

-- ----------------------------------------------------------------------------
-- 4c. Units within a subject
-- ----------------------------------------------------------------------------
create table if not exists public.syllabus_units (
  id          uuid primary key default gen_random_uuid(),
  subject_id  uuid not null references public.syllabus_subjects(id) on delete cascade,
  name        text not null,
  unit_number int,
  description text,
  sort_order  int  default 0
);

alter table public.syllabus_units enable row level security;

drop policy if exists "read syllabus units" on public.syllabus_units;
create policy "read syllabus units" on public.syllabus_units
  for select using (true);

drop policy if exists "admins manage syllabus units" on public.syllabus_units;
create policy "admins manage syllabus units" on public.syllabus_units
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 4d. Topics within a unit
-- ----------------------------------------------------------------------------
create table if not exists public.syllabus_topics (
  id             uuid      primary key default gen_random_uuid(),
  unit_id        uuid      not null references public.syllabus_units(id) on delete cascade,
  name           text      not null,
  description    text,
  sort_order     int       default 0,
  importance     text      default 'medium'
                           check (importance in ('high', 'medium', 'low')),
  has_mechanism  boolean   default false,
  mechanism_ids  text[]    default '{}',      -- cross-ref to mechanism library
  created_at     timestamptz default now()
);

alter table public.syllabus_topics enable row level security;

drop policy if exists "read syllabus topics" on public.syllabus_topics;
create policy "read syllabus topics" on public.syllabus_topics
  for select using (true);

drop policy if exists "admins manage syllabus topics" on public.syllabus_topics;
create policy "admins manage syllabus topics" on public.syllabus_topics
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 4e. Extend profiles: university preference and learning goals
-- ----------------------------------------------------------------------------
alter table public.profiles
  add column if not exists university_id uuid references public.universities(id),
  add column if not exists goals         text[] default '{}';


-- =============================================================================
-- SECTION 5: PREDICT IMPORTANT QUESTIONS -- SESSION HISTORY TABLE
-- Tracks uploaded PYQ PDFs and the AI-generated question predictions.
-- =============================================================================

-- Stores uploaded PYQ sessions and their AI-generated predictions
create table if not exists public.pyq_predict_sessions (
  id                  uuid      primary key default gen_random_uuid(),
  user_id             uuid      not null references auth.users(id) on delete cascade,
  subject_name        text      not null,
  university_name     text,
  year_range          text,                        -- e.g. '2021-2024'
  uploaded_file_names text[]    not null,          -- list of PDF filenames uploaded
  paper_count         int       not null,
  extracted_text      text,                        -- combined extracted text for AI analysis
  predictions         jsonb,                       -- AI-generated predictions JSON
  cache_key           text,                        -- references ai_cache.cache_key
  created_at          timestamptz default now()
);

alter table public.pyq_predict_sessions enable row level security;

-- Users can only read/write their own prediction sessions
drop policy if exists "own pyq sessions" on public.pyq_predict_sessions;
create policy "own pyq sessions" on public.pyq_predict_sessions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Ordered by most recent first; most queries will filter by user_id
create index if not exists idx_pyq_predict_user
  on public.pyq_predict_sessions(user_id, created_at desc);


-- =============================================================================
-- SECTION 6: TOPIC MASTERY TRACKING
-- Aggregated per-user, per-topic performance across quizzes and flashcards.
-- =============================================================================

create table if not exists public.topic_mastery (
  id              uuid      primary key default gen_random_uuid(),
  user_id         uuid      not null references auth.users(id) on delete cascade,
  topic_id        uuid      references public.syllabus_topics(id) on delete cascade,
  topic_name      text      not null,           -- denormalised for resilience if topic deleted
  quiz_attempts   int       default 0,
  quiz_correct    int       default 0,
  flashcard_easy  int       default 0,
  flashcard_hard  int       default 0,
  last_studied_at timestamptz,
  updated_at      timestamptz default now(),
  unique(user_id, topic_name)
);

alter table public.topic_mastery enable row level security;

-- Users can only read/write their own mastery data
drop policy if exists "own topic mastery" on public.topic_mastery;
create policy "own topic mastery" on public.topic_mastery
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
