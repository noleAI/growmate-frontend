-- GrowMate profile settings migration (safe, idempotent)
-- Run in Supabase SQL Editor.

begin;

alter table if exists public.profiles
  add column if not exists full_name text,
  add column if not exists email text,
  add column if not exists avatar_url text,
  add column if not exists grade_level text,
  add column if not exists active_subjects text[] not null default '{}',
  add column if not exists learning_preferences jsonb not null default '{}'::jsonb,
  add column if not exists recovery_mode_enabled boolean not null default false,
  add column if not exists consent_behavioral boolean not null default false,
  add column if not exists consent_analytics boolean not null default false,
  add column if not exists subscription_tier text not null default 'free',
  add column if not exists created_at timestamptz not null default timezone('utc', now()),
  add column if not exists updated_at timestamptz not null default timezone('utc', now()),
  add column if not exists last_active timestamptz;

-- Normalize old consent_flags JSONB (if project used nested consent shape before).
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'consent_flags'
  ) then
    update public.profiles
    set
      consent_behavioral = coalesce(
        (consent_flags ->> 'behavioral')::boolean,
        consent_behavioral,
        false
      ),
      consent_analytics = coalesce(
        (consent_flags ->> 'analytics')::boolean,
        consent_analytics,
        false
      )
    where true;
  end if;
end
$$;

-- Keep subscription tier constrained.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_subscription_tier_check'
  ) then
    alter table public.profiles
      add constraint profiles_subscription_tier_check
      check (subscription_tier in ('free', 'plus', 'pro'));
  end if;
end
$$;

-- Updated_at trigger.
create or replace function public.tg_set_profiles_updated_at()
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
execute function public.tg_set_profiles_updated_at();

alter table public.profiles enable row level security;

-- RLS: each user can read/write only their own profile row.
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

commit;
