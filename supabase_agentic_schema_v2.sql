-- GrowMate Agentic schema completion (idempotent)
-- Safe to run in Supabase SQL Editor after your current baseline schema.

begin;

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ===== ENUM TYPES =====
do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type public.user_role as enum ('student', 'mentor', 'admin');
  end if;
end
$$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'session_status') then
    create type public.session_status as enum ('active', 'paused', 'completed', 'cancelled');
  end if;
end
$$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'expert_config_category') then
    create type public.expert_config_category as enum (
      'academic',
      'empathy',
      'memory',
      'orchestrator',
      'system'
    );
  end if;
end
$$;

-- ===== BASE TABLE HARDENING =====
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role public.user_role not null default 'student',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  email text,
  avatar_url text,
  grade_level text,
  active_subjects text[] not null default '{}',
  learning_preferences jsonb not null default '{}'::jsonb,
  recovery_mode_enabled boolean not null default false,
  consent_behavioral boolean not null default false,
  consent_analytics boolean not null default false,
  subscription_tier text not null default 'free',
  last_active timestamptz
);

alter table public.profiles
  add column if not exists full_name text,
  add column if not exists role public.user_role,
  add column if not exists created_at timestamptz,
  add column if not exists updated_at timestamptz,
  add column if not exists email text,
  add column if not exists avatar_url text,
  add column if not exists grade_level text,
  add column if not exists active_subjects text[] not null default '{}',
  add column if not exists learning_preferences jsonb not null default '{}'::jsonb,
  add column if not exists recovery_mode_enabled boolean not null default false,
  add column if not exists consent_behavioral boolean not null default false,
  add column if not exists consent_analytics boolean not null default false,
  add column if not exists subscription_tier text not null default 'free',
  add column if not exists last_active timestamptz;

alter table public.profiles
  alter column role set default 'student',
  alter column created_at set default timezone('utc', now()),
  alter column updated_at set default timezone('utc', now());

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_subscription_tier_check'
  ) then
    alter table public.profiles
      add constraint profiles_subscription_tier_check
      check (subscription_tier in ('free', 'plus', 'pro'));
  end if;
end
$$;

create table if not exists public.learning_sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  start_time timestamptz not null default timezone('utc', now()),
  end_time timestamptz,
  status public.session_status not null default 'active'
);

alter table public.learning_sessions
  add column if not exists student_id uuid,
  add column if not exists start_time timestamptz,
  add column if not exists end_time timestamptz,
  add column if not exists status public.session_status;

alter table public.learning_sessions
  alter column start_time set default timezone('utc', now()),
  alter column status set default 'active';

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid references public.learning_sessions(id) on delete set null,
  event_type text not null,
  context jsonb not null default '{}'::jsonb,
  hitl_triggered boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.audit_logs
  add column if not exists student_id uuid,
  add column if not exists session_id uuid,
  add column if not exists event_type text,
  add column if not exists context jsonb not null default '{}'::jsonb,
  add column if not exists hitl_triggered boolean not null default false,
  add column if not exists created_at timestamptz not null default timezone('utc', now());

create table if not exists public.behavioral_signals (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references public.learning_sessions(id) on delete cascade,
  typing_speed double precision,
  correction_rate double precision,
  idle_time double precision,
  response_time double precision,
  trigger text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.behavioral_signals
  add column if not exists student_id uuid,
  add column if not exists session_id uuid,
  add column if not exists typing_speed double precision,
  add column if not exists correction_rate double precision,
  add column if not exists idle_time double precision,
  add column if not exists response_time double precision,
  add column if not exists trigger text,
  add column if not exists metadata jsonb not null default '{}'::jsonb,
  add column if not exists created_at timestamptz not null default timezone('utc', now());

create table if not exists public.episodic_memory (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid references public.learning_sessions(id) on delete set null,
  state jsonb not null default '{}'::jsonb,
  action text not null,
  outcome jsonb,
  reward double precision,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.episodic_memory
  add column if not exists student_id uuid,
  add column if not exists session_id uuid,
  add column if not exists state jsonb not null default '{}'::jsonb,
  add column if not exists action text,
  add column if not exists outcome jsonb,
  add column if not exists reward double precision,
  add column if not exists created_at timestamptz not null default timezone('utc', now());

create table if not exists public.q_table (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  state_discretized text not null,
  action text not null,
  q_value double precision not null default 0.0,
  visit_count integer not null default 0,
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.q_table
  add column if not exists student_id uuid,
  add column if not exists state_discretized text,
  add column if not exists action text,
  add column if not exists q_value double precision not null default 0.0,
  add column if not exists visit_count integer not null default 0,
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

create table if not exists public.question_bank (
  id uuid primary key default gen_random_uuid(),
  question_id text not null unique,
  subject text not null,
  topic text not null,
  subtopic text,
  grade_level text,
  difficulty integer,
  question_text text not null,
  answer_type text not null,
  canonical_answer text not null,
  accepted_answers text[] not null default '{}',
  hint_1 text,
  solution_short text,
  tags text[] not null default '{}',
  source text,
  quality_status text not null default 'draft',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.question_bank
  add column if not exists question_id text,
  add column if not exists subject text,
  add column if not exists topic text,
  add column if not exists subtopic text,
  add column if not exists grade_level text,
  add column if not exists difficulty integer,
  add column if not exists question_text text,
  add column if not exists answer_type text,
  add column if not exists canonical_answer text,
  add column if not exists accepted_answers text[] not null default '{}',
  add column if not exists hint_1 text,
  add column if not exists solution_short text,
  add column if not exists tags text[] not null default '{}',
  add column if not exists source text,
  add column if not exists quality_status text not null default 'draft',
  add column if not exists created_at timestamptz not null default timezone('utc', now()),
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

create table if not exists public.expert_configs (
  id uuid primary key default gen_random_uuid(),
  category public.expert_config_category not null,
  version varchar not null,
  payload jsonb not null,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

-- New operational tables for agentic pipeline visibility
create table if not exists public.answer_submissions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references public.learning_sessions(id) on delete cascade,
  question_id text not null,
  answer_text text not null,
  is_correct boolean,
  context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.diagnosis_results (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references public.learning_sessions(id) on delete cascade,
  submission_id uuid references public.answer_submissions(id) on delete set null,
  headline text,
  gap_analysis text,
  diagnosis_reason text,
  strengths jsonb not null default '[]'::jsonb,
  needs_review jsonb not null default '[]'::jsonb,
  next_suggested_topic text,
  final_mode text,
  confidence_score double precision,
  uncertainty_score double precision,
  risk_level text,
  requires_hitl boolean not null default false,
  intervention_plan jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.intervention_feedback (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references public.learning_sessions(id) on delete cascade,
  diagnosis_id uuid references public.diagnosis_results(id) on delete set null,
  option_id text not null,
  option_label text not null,
  mode text not null,
  remaining_rest_seconds integer not null default 0,
  skipped boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.inspection_snapshots (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid references public.learning_sessions(id) on delete set null,
  belief_distribution jsonb not null default '[]'::jsonb,
  plan_steps jsonb not null default '[]'::jsonb,
  mental_state_label text,
  confidence_score double precision,
  uncertainty_score double precision,
  q_values jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

-- ===== INDEXES =====
create index if not exists idx_learning_sessions_student_time
  on public.learning_sessions(student_id, start_time desc);

create unique index if not exists uq_learning_sessions_active_per_student
  on public.learning_sessions(student_id)
  where status = 'active';

create index if not exists idx_behavioral_signals_session_time
  on public.behavioral_signals(session_id, created_at desc);

create index if not exists idx_behavioral_signals_student_time
  on public.behavioral_signals(student_id, created_at desc);

create index if not exists idx_audit_logs_session_time
  on public.audit_logs(session_id, created_at desc);

create index if not exists idx_audit_logs_student_time
  on public.audit_logs(student_id, created_at desc);

create index if not exists idx_episodic_memory_student_time
  on public.episodic_memory(student_id, created_at desc);

create index if not exists idx_q_table_student_updated
  on public.q_table(student_id, updated_at desc);

create unique index if not exists uq_q_table_student_state_action
  on public.q_table(student_id, state_discretized, action);

create index if not exists idx_answer_submissions_session_time
  on public.answer_submissions(session_id, created_at desc);

create index if not exists idx_diagnosis_results_session_time
  on public.diagnosis_results(session_id, created_at desc);

create index if not exists idx_intervention_feedback_session_time
  on public.intervention_feedback(session_id, created_at desc);

create index if not exists idx_inspection_snapshots_session_time
  on public.inspection_snapshots(session_id, created_at desc);

-- ===== TIMESTAMP TRIGGERS =====
create or replace function public.tg_set_timestamp_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row
execute function public.tg_set_timestamp_updated_at();

drop trigger if exists trg_q_table_updated_at on public.q_table;
create trigger trg_q_table_updated_at
before update on public.q_table
for each row
execute function public.tg_set_timestamp_updated_at();

drop trigger if exists trg_question_bank_updated_at on public.question_bank;
create trigger trg_question_bank_updated_at
before update on public.question_bank
for each row
execute function public.tg_set_timestamp_updated_at();

-- ===== RPC FUNCTIONS USED BY FRONTEND =====
-- Drop first to avoid 42P13 when previous deployed versions used different
-- default-parameter definitions.
drop function if exists public.upsert_q_value(text, text, double precision, double precision);
drop function if exists public.insert_audit_event(uuid, text, jsonb, boolean);
drop function if exists public.save_interaction_feedback(uuid, text, text, text, text, text, jsonb);
drop function if exists public.complete_learning_session(uuid, public.session_status);

create or replace function public.start_learning_session()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_session_id uuid;
begin
  v_student_id := auth.uid();
  if v_student_id is null then
    raise exception 'UNAUTHENTICATED';
  end if;

  select id
    into v_session_id
  from public.learning_sessions
  where student_id = v_student_id
    and status = 'active'
  order by start_time desc
  limit 1;

  if v_session_id is null then
    insert into public.learning_sessions (
      student_id,
      start_time,
      status
    )
    values (
      v_student_id,
      timezone('utc', now()),
      'active'
    )
    returning id into v_session_id;
  end if;

  return v_session_id;
end;
$$;

create or replace function public.insert_behavioral_signals_batch(
  p_session_id uuid,
  p_signals jsonb
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_count integer := 0;
begin
  v_student_id := auth.uid();
  if v_student_id is null then
    raise exception 'UNAUTHENTICATED';
  end if;

  if not exists (
    select 1
    from public.learning_sessions
    where id = p_session_id
      and student_id = v_student_id
  ) then
    raise exception 'SESSION_NOT_OWNED';
  end if;

  if p_signals is null or jsonb_typeof(p_signals) <> 'array' then
    return 0;
  end if;

  with parsed as (
    select
      nullif(elem ->> 'typing_speed', '')::double precision as typing_speed,
      nullif(elem ->> 'correction_rate', '')::double precision as correction_rate,
      nullif(elem ->> 'idle_time', '')::double precision as idle_time,
      nullif(elem ->> 'response_time', '')::double precision as response_time,
      nullif(elem ->> 'trigger', '')::text as trigger,
      case
        when nullif(elem ->> 'created_at', '') is null then timezone('utc', now())
        else (elem ->> 'created_at')::timestamptz
      end as created_at,
      elem as metadata
    from jsonb_array_elements(p_signals) as elem
  )
  insert into public.behavioral_signals (
    student_id,
    session_id,
    typing_speed,
    correction_rate,
    idle_time,
    response_time,
    trigger,
    metadata,
    created_at
  )
  select
    v_student_id,
    p_session_id,
    typing_speed,
    correction_rate,
    idle_time,
    response_time,
    trigger,
    metadata,
    created_at
  from parsed;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

create or replace function public.upsert_q_value(
  p_state_discretized text,
  p_action text,
  p_reward double precision,
  p_alpha double precision default 0.2
)
returns table (
  q_value double precision,
  visit_count integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_alpha double precision;
begin
  v_student_id := auth.uid();
  if v_student_id is null then
    raise exception 'UNAUTHENTICATED';
  end if;

  if p_state_discretized is null or trim(p_state_discretized) = '' then
    raise exception 'INVALID_STATE';
  end if;

  if p_action is null or trim(p_action) = '' then
    raise exception 'INVALID_ACTION';
  end if;

  v_alpha := coalesce(p_alpha, 0.2);
  if v_alpha <= 0 or v_alpha > 1 then
    v_alpha := 0.2;
  end if;

  return query
  insert into public.q_table (
    student_id,
    state_discretized,
    action,
    q_value,
    visit_count,
    updated_at
  )
  values (
    v_student_id,
    p_state_discretized,
    p_action,
    coalesce(p_reward, 0),
    1,
    timezone('utc', now())
  )
  on conflict (student_id, state_discretized, action)
  do update set
    q_value = public.q_table.q_value + v_alpha * (coalesce(p_reward, 0) - public.q_table.q_value),
    visit_count = public.q_table.visit_count + 1,
    updated_at = timezone('utc', now())
  returning public.q_table.q_value, public.q_table.visit_count;
end;
$$;

create or replace function public.insert_audit_event(
  p_session_id uuid,
  p_event_type text,
  p_context jsonb default '{}'::jsonb,
  p_hitl_triggered boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_event_id uuid;
begin
  v_student_id := auth.uid();
  if v_student_id is null then
    raise exception 'UNAUTHENTICATED';
  end if;

  if p_session_id is not null and not exists (
    select 1
    from public.learning_sessions
    where id = p_session_id
      and student_id = v_student_id
  ) then
    raise exception 'SESSION_NOT_OWNED';
  end if;

  insert into public.audit_logs (
    student_id,
    session_id,
    event_type,
    context,
    hitl_triggered,
    created_at
  )
  values (
    v_student_id,
    p_session_id,
    coalesce(p_event_type, 'unknown_event'),
    coalesce(p_context, '{}'::jsonb),
    coalesce(p_hitl_triggered, false),
    timezone('utc', now())
  )
  returning id into v_event_id;

  return v_event_id;
end;
$$;

create or replace function public.save_interaction_feedback(
  p_session_id uuid,
  p_submission_id text,
  p_diagnosis_id text,
  p_event_name text,
  p_memory_scope text,
  p_reason text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_event_id uuid;
  v_reward double precision;
  v_next_topic text;
begin
  v_student_id := auth.uid();
  if v_student_id is null then
    raise exception 'UNAUTHENTICATED';
  end if;

  if not exists (
    select 1
    from public.learning_sessions
    where id = p_session_id
      and student_id = v_student_id
  ) then
    raise exception 'SESSION_NOT_OWNED';
  end if;

  v_reward := case
    when p_event_name = 'Plan Accepted' then 0.9
    when p_event_name = 'Plan Rejected' then -0.2
    else 0.1
  end;

  v_next_topic := case
    when p_event_name = 'Plan Rejected' then 'Flashcard nhẹ nhàng'
    else coalesce(p_metadata ->> 'nextSuggestedTopic', 'Review Đạo hàm')
  end;

  insert into public.episodic_memory (
    student_id,
    session_id,
    state,
    action,
    outcome,
    reward,
    created_at
  )
  values (
    v_student_id,
    p_session_id,
    jsonb_build_object(
      'submissionId', p_submission_id,
      'diagnosisId', p_diagnosis_id,
      'memoryScope', p_memory_scope
    ),
    coalesce(p_event_name, 'unknown_event'),
    jsonb_build_object(
      'reason', p_reason,
      'metadata', coalesce(p_metadata, '{}'::jsonb),
      'nextSuggestedTopic', v_next_topic
    ),
    v_reward,
    timezone('utc', now())
  )
  returning id into v_event_id;

  perform public.insert_audit_event(
    p_session_id,
    'interaction_feedback',
    jsonb_build_object(
      'eventName', p_event_name,
      'memoryScope', p_memory_scope,
      'submissionId', p_submission_id,
      'diagnosisId', p_diagnosis_id
    ),
    false
  );

  return jsonb_build_object(
    'event_id', v_event_id,
    'nextSuggestedTopic', v_next_topic
  );
end;
$$;

create or replace function public.complete_learning_session(
  p_session_id uuid,
  p_status public.session_status default 'completed'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
begin
  v_student_id := auth.uid();
  if v_student_id is null then
    raise exception 'UNAUTHENTICATED';
  end if;

  update public.learning_sessions
  set
    status = coalesce(p_status, 'completed'),
    end_time = coalesce(end_time, timezone('utc', now()))
  where id = p_session_id
    and student_id = v_student_id;
end;
$$;

-- ===== RLS =====
alter table public.profiles enable row level security;
alter table public.learning_sessions enable row level security;
alter table public.audit_logs enable row level security;
alter table public.behavioral_signals enable row level security;
alter table public.episodic_memory enable row level security;
alter table public.q_table enable row level security;
alter table public.question_bank enable row level security;
alter table public.expert_configs enable row level security;
alter table public.answer_submissions enable row level security;
alter table public.diagnosis_results enable row level security;
alter table public.intervention_feedback enable row level security;
alter table public.inspection_snapshots enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
  on public.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists learning_sessions_select_own on public.learning_sessions;
create policy learning_sessions_select_own
  on public.learning_sessions
  for select
  to authenticated
  using (auth.uid() = student_id);

drop policy if exists learning_sessions_insert_own on public.learning_sessions;
create policy learning_sessions_insert_own
  on public.learning_sessions
  for insert
  to authenticated
  with check (auth.uid() = student_id);

drop policy if exists learning_sessions_update_own on public.learning_sessions;
create policy learning_sessions_update_own
  on public.learning_sessions
  for update
  to authenticated
  using (auth.uid() = student_id)
  with check (auth.uid() = student_id);

drop policy if exists behavioral_signals_select_own on public.behavioral_signals;
create policy behavioral_signals_select_own
  on public.behavioral_signals
  for select
  to authenticated
  using (auth.uid() = student_id);

drop policy if exists behavioral_signals_insert_own on public.behavioral_signals;
create policy behavioral_signals_insert_own
  on public.behavioral_signals
  for insert
  to authenticated
  with check (auth.uid() = student_id);

drop policy if exists audit_logs_select_own on public.audit_logs;
create policy audit_logs_select_own
  on public.audit_logs
  for select
  to authenticated
  using (auth.uid() = student_id);

drop policy if exists audit_logs_insert_own on public.audit_logs;
create policy audit_logs_insert_own
  on public.audit_logs
  for insert
  to authenticated
  with check (auth.uid() = student_id);

drop policy if exists episodic_memory_select_own on public.episodic_memory;
create policy episodic_memory_select_own
  on public.episodic_memory
  for select
  to authenticated
  using (auth.uid() = student_id);

drop policy if exists episodic_memory_insert_own on public.episodic_memory;
create policy episodic_memory_insert_own
  on public.episodic_memory
  for insert
  to authenticated
  with check (auth.uid() = student_id);

drop policy if exists q_table_select_own on public.q_table;
create policy q_table_select_own
  on public.q_table
  for select
  to authenticated
  using (auth.uid() = student_id);

drop policy if exists q_table_insert_own on public.q_table;
create policy q_table_insert_own
  on public.q_table
  for insert
  to authenticated
  with check (auth.uid() = student_id);

drop policy if exists q_table_update_own on public.q_table;
create policy q_table_update_own
  on public.q_table
  for update
  to authenticated
  using (auth.uid() = student_id)
  with check (auth.uid() = student_id);

drop policy if exists answer_submissions_select_own on public.answer_submissions;
create policy answer_submissions_select_own
  on public.answer_submissions
  for select
  to authenticated
  using (auth.uid() = student_id);

drop policy if exists answer_submissions_insert_own on public.answer_submissions;
create policy answer_submissions_insert_own
  on public.answer_submissions
  for insert
  to authenticated
  with check (auth.uid() = student_id);

drop policy if exists diagnosis_results_select_own on public.diagnosis_results;
create policy diagnosis_results_select_own
  on public.diagnosis_results
  for select
  to authenticated
  using (auth.uid() = student_id);

drop policy if exists diagnosis_results_insert_own on public.diagnosis_results;
create policy diagnosis_results_insert_own
  on public.diagnosis_results
  for insert
  to authenticated
  with check (auth.uid() = student_id);

drop policy if exists intervention_feedback_select_own on public.intervention_feedback;
create policy intervention_feedback_select_own
  on public.intervention_feedback
  for select
  to authenticated
  using (auth.uid() = student_id);

drop policy if exists intervention_feedback_insert_own on public.intervention_feedback;
create policy intervention_feedback_insert_own
  on public.intervention_feedback
  for insert
  to authenticated
  with check (auth.uid() = student_id);

drop policy if exists inspection_snapshots_select_own on public.inspection_snapshots;
create policy inspection_snapshots_select_own
  on public.inspection_snapshots
  for select
  to authenticated
  using (auth.uid() = student_id);

drop policy if exists inspection_snapshots_insert_own on public.inspection_snapshots;
create policy inspection_snapshots_insert_own
  on public.inspection_snapshots
  for insert
  to authenticated
  with check (auth.uid() = student_id);

drop policy if exists question_bank_select_authenticated on public.question_bank;
create policy question_bank_select_authenticated
  on public.question_bank
  for select
  to authenticated
  using (true);

drop policy if exists expert_configs_select_active on public.expert_configs;
create policy expert_configs_select_active
  on public.expert_configs
  for select
  to authenticated
  using (is_active = true);

-- ===== GRANTS =====
grant execute on function public.start_learning_session() to authenticated;
grant execute on function public.insert_behavioral_signals_batch(uuid, jsonb) to authenticated;
grant execute on function public.upsert_q_value(text, text, double precision, double precision) to authenticated;
grant execute on function public.insert_audit_event(uuid, text, jsonb, boolean) to authenticated;
grant execute on function public.save_interaction_feedback(uuid, text, text, text, text, text, jsonb) to authenticated;
grant execute on function public.complete_learning_session(uuid, public.session_status) to authenticated;

commit;
