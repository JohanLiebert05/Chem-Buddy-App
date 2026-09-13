-- ============================================================
-- ChemBuddy — Migration 004: Curated MSc Organic Reaction Database
-- ============================================================

-- 1. Curated Reactions Table
create table if not exists public.curated_reactions (
  id uuid primary key default gen_random_uuid(),
  reaction_id text not null unique,
  reaction_name text not null,
  reaction_class text not null,
  subclass text,
  description text not null,
  difficulty text default 'Intermediate',
  conditions text,
  solvent text,
  temperature text,
  major_product_rule text not null,
  selectivity_notes text,
  stereochemistry_notes text,
  supported boolean default true,
  source_reference text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. Reaction Examples Table
create table if not exists public.reaction_examples (
  id uuid primary key default gen_random_uuid(),
  example_id text not null unique,
  reaction_id text not null references public.curated_reactions (reaction_id) on delete cascade,
  reactant_smiles text not null,
  reagent_smiles text,
  solvent text,
  temperature text,
  expected_product_smiles text not null,
  expected_product_name text not null,
  stereochemical_outcome text,
  example_notes text,
  created_at timestamptz default now()
);

-- 3. Reaction Mechanisms Table
create table if not exists public.reaction_mechanisms_v2 (
  id uuid primary key default gen_random_uuid(),
  reaction_id text not null unique references public.curated_reactions (reaction_id) on delete cascade,
  mechanism_title text not null,
  overall_scheme_svg text,
  driving_force text,
  thermodynamic_notes text,
  kinetic_notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 4. Mechanism Steps Table
create table if not exists public.mechanism_steps_v2 (
  id uuid primary key default gen_random_uuid(),
  step_id text not null unique,
  reaction_id text not null references public.curated_reactions (reaction_id) on delete cascade,
  step_number int not null,
  step_title text not null,
  step_description text not null,
  intermediate_id text,
  intermediate_smiles text,
  step_svg text,
  bond_changes text,
  charge_changes text,
  is_rate_determining boolean default false,
  is_reversible boolean default false,
  created_at timestamptz default now()
);

-- 5. Mechanism Electron Flows Table
create table if not exists public.mechanism_electron_flows (
  id uuid primary key default gen_random_uuid(),
  electron_flow_id text not null unique,
  reaction_id text not null references public.curated_reactions (reaction_id) on delete cascade,
  step_id text not null references public.mechanism_steps_v2 (step_id) on delete cascade,
  source_type text not null check (source_type in ('lone_pair', 'bond', 'pi_bond', 'negative_charge')),
  source_atom_role text not null,
  source_atom_identifier text not null,
  target_type text not null check (target_type in ('atom', 'bond', 'positive_charge')),
  target_atom_role text not null,
  target_atom_identifier text not null,
  flow_type text not null check (flow_type in ('lone_pair_attack', 'bond_break', 'pi_attack', 'proton_transfer', 'resonance', 'elimination', 'bond_formation')),
  arrow_type text not null check (arrow_type in ('curved_full', 'curved_half')),
  description text not null,
  created_at timestamptz default now()
);

-- 6. Saved Student Reactions Table (for Library bookmarking)
create table if not exists public.saved_student_reactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  reaction_id text not null references public.curated_reactions (reaction_id) on delete cascade,
  custom_notes text,
  user_reactant_smiles text,
  user_product_smiles text,
  created_at timestamptz default now(),
  unique (user_id, reaction_id)
);

-- ============================================================
-- INDEXES
-- ============================================================
create index if not exists idx_curated_rxn_id on public.curated_reactions (reaction_id);
create index if not exists idx_curated_rxn_class on public.curated_reactions (reaction_class);
create index if not exists idx_curated_rxn_name on public.curated_reactions (reaction_name);
create index if not exists idx_curated_rxn_supported on public.curated_reactions (supported);
create index if not exists idx_rxn_examples_rxn_id on public.reaction_examples (reaction_id);
create index if not exists idx_mech_steps_rxn_id on public.mechanism_steps_v2 (reaction_id);
create index if not exists idx_elec_flows_step_id on public.mechanism_electron_flows (step_id);
create index if not exists idx_saved_student_rxn on public.saved_student_reactions (user_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================
alter table public.curated_reactions enable row level security;
alter table public.reaction_examples enable row level security;
alter table public.reaction_mechanisms_v2 enable row level security;
alter table public.mechanism_steps_v2 enable row level security;
alter table public.mechanism_electron_flows enable row level security;
alter table public.saved_student_reactions enable row level security;

-- Students can read all supported curated reactions
create policy "students read supported reactions"
  on public.curated_reactions for select
  using (supported = true);

-- Admins manage curated reactions
create policy "admins manage reactions"
  on public.curated_reactions for all
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

-- Students read reaction examples
create policy "students read reaction examples"
  on public.reaction_examples for select
  using (
    exists (
      select 1 from public.curated_reactions
      where curated_reactions.reaction_id = reaction_examples.reaction_id
        and curated_reactions.supported = true
    )
  );

create policy "admins manage reaction examples"
  on public.reaction_examples for all
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- Students read mechanisms & steps
create policy "students read mechanisms"
  on public.reaction_mechanisms_v2 for select
  using (true);

create policy "admins manage mechanisms"
  on public.reaction_mechanisms_v2 for all
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

create policy "students read mechanism steps"
  on public.mechanism_steps_v2 for select
  using (true);

create policy "admins manage mechanism steps"
  on public.mechanism_steps_v2 for all
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

create policy "students read electron flows"
  on public.mechanism_electron_flows for select
  using (true);

create policy "admins manage electron flows"
  on public.mechanism_electron_flows for all
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- Student Saved Reactions (Full CRUD on own rows)
create policy "own saved reactions"
  on public.saved_student_reactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
