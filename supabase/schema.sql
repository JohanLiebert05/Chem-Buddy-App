-- Chem Buddy — run this in the Supabase SQL editor.
-- Enable Row Level Security so each student only sees their own rows.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  university text,
  semester int,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  code text not null,
  teacher text,
  color_hex text,
  is_elective boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subject_id uuid not null,
  date date not null,
  status text not null check (status in ('present', 'absent', 'postponed')),
  slot_id text,
  created_at timestamptz default now(),
  unique (user_id, subject_id, date, slot_id)
);

create table if not exists public.timetable_slots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subject_id uuid not null,
  weekday int not null,
  start_minutes int not null,
  end_minutes int not null,
  room text
);

create table if not exists public.academic_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subject_id uuid,
  title text not null,
  type text not null check (type in ('test', 'assignment', 'seminar')),
  due_date date not null,
  description text,
  completed boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subject_id uuid,
  title text not null,
  body text not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.attendance_records enable row level security;
alter table public.timetable_slots enable row level security;
alter table public.academic_events enable row level security;
alter table public.notes enable row level security;

create policy "own profiles" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "own subjects" on public.subjects
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own attendance" on public.attendance_records
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own timetable" on public.timetable_slots
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own events" on public.academic_events
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own notes" on public.notes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
