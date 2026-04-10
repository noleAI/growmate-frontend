-- GrowMate THPT Math 2026 quiz schema (idempotent)
-- Run in Supabase SQL Editor after baseline schema.

begin;

create extension if not exists "pgcrypto";

create table if not exists public.quiz_exam_blueprints (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  subject text not null,
  exam_year integer not null,
  config jsonb not null,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.quiz_exam_blueprints
  add column if not exists code text,
  add column if not exists subject text,
  add column if not exists exam_year integer,
  add column if not exists config jsonb,
  add column if not exists is_active boolean not null default true,
  add column if not exists created_at timestamptz not null default timezone('utc', now()),
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

create table if not exists public.quiz_question_template (
  id uuid primary key default gen_random_uuid(),
  subject text not null default 'math',
  topic_code text,
  topic_name text,
  exam_year integer not null default 2026,
  question_type text not null,
  part_no smallint not null,
  difficulty_level integer not null default 2,
  content text not null,
  media_url text,
  payload jsonb not null,
  metadata jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  published_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.quiz_question_template
  add column if not exists subject text not null default 'math',
  add column if not exists topic_code text,
  add column if not exists topic_name text,
  add column if not exists exam_year integer not null default 2026,
  add column if not exists question_type text,
  add column if not exists part_no smallint,
  add column if not exists difficulty_level integer not null default 2,
  add column if not exists content text,
  add column if not exists media_url text,
  add column if not exists payload jsonb,
  add column if not exists metadata jsonb not null default '{}'::jsonb,
  add column if not exists is_active boolean not null default true,
  add column if not exists published_by uuid,
  add column if not exists created_at timestamptz not null default timezone('utc', now()),
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'quiz_question_template_question_type_check'
  ) then
    alter table public.quiz_question_template
      add constraint quiz_question_template_question_type_check
      check (question_type in ('MULTIPLE_CHOICE', 'TRUE_FALSE_CLUSTER', 'SHORT_ANSWER'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'quiz_question_template_part_no_check'
  ) then
    alter table public.quiz_question_template
      add constraint quiz_question_template_part_no_check
      check (part_no in (1, 2, 3));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'quiz_question_template_difficulty_level_check'
  ) then
    alter table public.quiz_question_template
      add constraint quiz_question_template_difficulty_level_check
      check (difficulty_level between 1 and 5);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'quiz_question_template_exam_year_check'
  ) then
    alter table public.quiz_question_template
      add constraint quiz_question_template_exam_year_check
      check (exam_year >= 2026);
  end if;
end
$$;

create table if not exists public.quiz_question_attempts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid references public.learning_sessions(id) on delete set null,
  question_template_id uuid not null references public.quiz_question_template(id) on delete cascade,
  question_type text not null,
  user_answer jsonb not null,
  evaluation jsonb not null default '{}'::jsonb,
  score numeric(6, 3) not null default 0,
  max_score numeric(6, 3) not null,
  is_correct boolean not null default false,
  submitted_at timestamptz not null default timezone('utc', now())
);

alter table public.quiz_question_attempts
  add column if not exists student_id uuid,
  add column if not exists session_id uuid,
  add column if not exists question_template_id uuid,
  add column if not exists question_type text,
  add column if not exists user_answer jsonb,
  add column if not exists evaluation jsonb not null default '{}'::jsonb,
  add column if not exists score numeric(6, 3) not null default 0,
  add column if not exists max_score numeric(6, 3),
  add column if not exists is_correct boolean not null default false,
  add column if not exists submitted_at timestamptz not null default timezone('utc', now());

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'quiz_question_attempts_question_type_check'
  ) then
    alter table public.quiz_question_attempts
      add constraint quiz_question_attempts_question_type_check
      check (question_type in ('MULTIPLE_CHOICE', 'TRUE_FALSE_CLUSTER', 'SHORT_ANSWER'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'quiz_question_attempts_score_range_check'
  ) then
    alter table public.quiz_question_attempts
      add constraint quiz_question_attempts_score_range_check
      check (score >= 0 and max_score > 0 and score <= max_score and max_score <= 1.0);
  end if;
end
$$;

create unique index if not exists uq_quiz_exam_blueprints_code
  on public.quiz_exam_blueprints(code);

create index if not exists idx_quiz_question_template_lookup
  on public.quiz_question_template(subject, exam_year, question_type, difficulty_level);

create index if not exists idx_quiz_question_template_topic
  on public.quiz_question_template(topic_code, topic_name);

create index if not exists idx_quiz_question_template_active
  on public.quiz_question_template(is_active)
  where is_active = true;

create index if not exists idx_quiz_question_template_payload_gin
  on public.quiz_question_template using gin(payload);

create index if not exists idx_quiz_question_attempts_student_time
  on public.quiz_question_attempts(student_id, submitted_at desc);

create index if not exists idx_quiz_question_attempts_template_time
  on public.quiz_question_attempts(question_template_id, submitted_at desc);

create or replace function public.tg_set_timestamp_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_quiz_exam_blueprints_updated_at on public.quiz_exam_blueprints;
create trigger trg_quiz_exam_blueprints_updated_at
before update on public.quiz_exam_blueprints
for each row
execute function public.tg_set_timestamp_updated_at();

drop trigger if exists trg_quiz_question_template_updated_at on public.quiz_question_template;
create trigger trg_quiz_question_template_updated_at
before update on public.quiz_question_template
for each row
execute function public.tg_set_timestamp_updated_at();

alter table public.quiz_exam_blueprints enable row level security;
alter table public.quiz_question_template enable row level security;
alter table public.quiz_question_attempts enable row level security;

drop policy if exists quiz_exam_blueprints_select_active on public.quiz_exam_blueprints;
create policy quiz_exam_blueprints_select_active
  on public.quiz_exam_blueprints
  for select
  to authenticated
  using (is_active = true);

drop policy if exists quiz_question_template_select_active on public.quiz_question_template;
create policy quiz_question_template_select_active
  on public.quiz_question_template
  for select
  to authenticated
  using (is_active = true);

drop policy if exists quiz_question_attempts_select_own on public.quiz_question_attempts;
create policy quiz_question_attempts_select_own
  on public.quiz_question_attempts
  for select
  to authenticated
  using (auth.uid() = student_id);

drop policy if exists quiz_question_attempts_insert_own on public.quiz_question_attempts;
create policy quiz_question_attempts_insert_own
  on public.quiz_question_attempts
  for insert
  to authenticated
  with check (auth.uid() = student_id);

drop policy if exists quiz_question_attempts_update_own on public.quiz_question_attempts;
create policy quiz_question_attempts_update_own
  on public.quiz_question_attempts
  for update
  to authenticated
  using (auth.uid() = student_id)
  with check (auth.uid() = student_id);

grant select on public.quiz_exam_blueprints to authenticated;
grant select on public.quiz_question_template to authenticated;
grant select, insert, update on public.quiz_question_attempts to authenticated;

insert into public.quiz_exam_blueprints (
  code,
  subject,
  exam_year,
  config,
  is_active
)
values (
  'THPT_MATH_2026',
  'math',
  2026,
  jsonb_build_object(
    'duration_minutes', 90,
    'total_questions', 22,
    'parts', jsonb_build_array(
      jsonb_build_object(
        'part_no', 1,
        'question_type', 'MULTIPLE_CHOICE',
        'question_count', 12,
        'total_points', 3.0,
        'score_per_question', 0.25
      ),
      jsonb_build_object(
        'part_no', 2,
        'question_type', 'TRUE_FALSE_CLUSTER',
        'question_count', 4,
        'total_points', 4.0,
        'progressive_scoring', jsonb_build_object(
          '0', 0.0,
          '1', 0.1,
          '2', 0.25,
          '3', 0.5,
          '4', 1.0
        )
      ),
      jsonb_build_object(
        'part_no', 3,
        'question_type', 'SHORT_ANSWER',
        'question_count', 6,
        'total_points', 3.0,
        'score_per_question', 0.5
      )
    )
  ),
  true
)
on conflict (code)
do update set
  subject = excluded.subject,
  exam_year = excluded.exam_year,
  config = excluded.config,
  is_active = excluded.is_active,
  updated_at = timezone('utc', now());

insert into public.quiz_question_template (
  id,
  subject,
  topic_code,
  topic_name,
  exam_year,
  question_type,
  part_no,
  difficulty_level,
  content,
  payload,
  metadata,
  is_active
)
values
  (
    '11111111-1111-4111-8111-111111111111',
    'math',
    'derivative',
    'Đạo hàm',
    2026,
    'SHORT_ANSWER',
    3,
    2,
    'Tính đạo hàm của hàm số',
    jsonb_build_object(
      'exact_answer', '12x^2 + 4x',
      'accepted_answers', jsonb_build_array('12x^2+4x', '4x+12x^2', '12x²+4x'),
      'explanation', 'Áp dụng quy tắc đạo hàm: y'' = 12x^2 + 4x'
    ),
    jsonb_build_object('formula', 'y = 4x³ + 2x² - 5'),
    true
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    'math',
    'logarithm',
    'Hàm mũ - logarit',
    2026,
    'MULTIPLE_CHOICE',
    1,
    1,
    'Hàm số nào đồng biến trên R?',
    jsonb_build_object(
      'options', jsonb_build_array(
        jsonb_build_object('id', 'A', 'text', 'y = 2^x'),
        jsonb_build_object('id', 'B', 'text', 'y = (1/2)^x'),
        jsonb_build_object('id', 'C', 'text', 'y = -x^2'),
        jsonb_build_object('id', 'D', 'text', 'y = -|x|')
      ),
      'correct_option_id', 'A',
      'explanation', 'Cơ số a>1 thì hàm mũ a^x đồng biến trên R.'
    ),
    '{}'::jsonb,
    true
  ),
  (
    '33333333-3333-4333-8333-333333333333',
    'math',
    'function_analysis',
    'Khảo sát hàm số',
    2026,
    'TRUE_FALSE_CLUSTER',
    2,
    3,
    'Xét tính đúng sai của các mệnh đề về hàm số đã cho.',
    jsonb_build_object(
      'sub_questions', jsonb_build_array(
        jsonb_build_object(
          'id', 'a',
          'text', 'Hàm số đạt cực đại tại x = 1.',
          'is_true', true,
          'explanation', 'Đạo hàm đổi dấu từ + sang - tại x = 1.'
        ),
        jsonb_build_object(
          'id', 'b',
          'text', 'Giá trị nhỏ nhất trên [-1;2] bằng -3.',
          'is_true', false,
          'explanation', 'Tính y(-1), y(2) cho thấy min = -5.'
        ),
        jsonb_build_object(
          'id', 'c',
          'text', 'Đồ thị có đúng 2 đường tiệm cận.',
          'is_true', true,
          'explanation', 'Có 1 tiệm cận đứng và 1 tiệm cận ngang.'
        ),
        jsonb_build_object(
          'id', 'd',
          'text', 'y'' < 0 với mọi x trong (1;3).',
          'is_true', true,
          'explanation', 'Bảng biến thiên cho thấy hàm giảm trên khoảng này.'
        )
      ),
      'general_hint', 'Lập bảng biến thiên trước rồi mới xét từng mệnh đề.'
    ),
    '{}'::jsonb,
    true
  )
on conflict (id)
do update set
  subject = excluded.subject,
  topic_code = excluded.topic_code,
  topic_name = excluded.topic_name,
  exam_year = excluded.exam_year,
  question_type = excluded.question_type,
  part_no = excluded.part_no,
  difficulty_level = excluded.difficulty_level,
  content = excluded.content,
  payload = excluded.payload,
  metadata = excluded.metadata,
  is_active = excluded.is_active,
  updated_at = timezone('utc', now());

commit;
