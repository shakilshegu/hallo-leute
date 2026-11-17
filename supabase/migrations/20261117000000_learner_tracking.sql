-- Hallo Leute: learner accounts and progress tracking.
--
-- Run once in Supabase (Dashboard → SQL Editor → paste → Run), or with the
-- Supabase CLI: `supabase db push`.
--
-- Every learner (guests included) is a row in auth.users. Guests are
-- anonymous users. When they "save progress" with Google or email, the same
-- user id is kept, so no data has to move.

-- ─────────────────────────── profiles ───────────────────────────
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  name        text not null default '',
  level       text,                       -- a0 | a1 | a2 | b1
  daily_goal  text not null default 'regular',
  goals       text[] not null default '{}',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ───────────────────── per-word progress (current state) ─────────────────────
create table public.word_progress (
  user_id       uuid not null references auth.users (id) on delete cascade,
  word_key      text not null,             -- e.g. 'Bahnhof|noun'
  first_seen    date not null,
  last_seen     date not null,
  learned_on    date,                      -- null = seen but not learned yet
  due           date not null,             -- next spaced-repetition review
  times_seen    integer not null default 0,
  times_correct integer not null default 0,
  times_again   integer not null default 0,
  box           smallint not null default 0, -- 0 = new, 1..5 (5 = mastered)
  updated_at    timestamptz not null default now(),
  primary key (user_id, word_key)
);
create index word_progress_learned_idx on public.word_progress (user_id, learned_on);

-- ─────────────────────────── daily activity ───────────────────────────
create table public.daily_activity (
  user_id    uuid not null references auth.users (id) on delete cascade,
  day        date not null,
  new_words  integer not null default 0,
  reviews    integer not null default 0,
  again      integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

-- ──────────────────── answer log (full history, append-only) ────────────────────
create table public.answer_events (
  id          uuid primary key,            -- generated on the phone (safe retries)
  user_id     uuid not null references auth.users (id) on delete cascade,
  word_key    text not null,
  knew_it     boolean not null,
  review      boolean not null,            -- true = word was already learned
  answered_at timestamptz not null,
  received_at timestamptz not null default now()
);
create index answer_events_user_time_idx on public.answer_events (user_id, answered_at);
create index answer_events_word_idx on public.answer_events (word_key);

-- ─────────────────────── row level security ───────────────────────
-- Each learner can only read and write their own rows.
alter table public.profiles       enable row level security;
alter table public.word_progress  enable row level security;
alter table public.daily_activity enable row level security;
alter table public.answer_events  enable row level security;

create policy "own profile" on public.profiles
  for all to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "own word progress" on public.word_progress
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "own daily activity" on public.daily_activity
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Answers can be added and read, never edited or deleted by the app.
create policy "read own answers" on public.answer_events
  for select to authenticated
  using (user_id = (select auth.uid()));
create policy "add own answers" on public.answer_events
  for insert to authenticated
  with check (user_id = (select auth.uid()));

-- ─────────────────────── account deletion ───────────────────────
-- Required by Google Play for apps with accounts. Deleting the auth user
-- cascades to every table above.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- ───────────────────── admin views (not exposed to the app) ─────────────────────
-- The `admin` schema is not in the API's exposed schemas, so only the
-- dashboard / service role can read these.
create schema if not exists admin;
revoke all on schema admin from public, anon, authenticated;

create or replace view admin.learners as
select
  u.id                                   as user_id,
  coalesce(p.name, '')                   as name,
  u.email,
  u.is_anonymous                         as is_guest,
  p.level,
  p.daily_goal,
  p.goals,
  u.created_at                           as joined_at,
  (select count(*) from public.word_progress w
     where w.user_id = u.id and w.learned_on is not null) as words_learned,
  (select count(*) from public.word_progress w
     where w.user_id = u.id and w.box >= 5)               as words_mastered,
  (select count(*) from public.answer_events e
     where e.user_id = u.id)                              as total_answers,
  (select max(e.answered_at) from public.answer_events e
     where e.user_id = u.id)                              as last_active
from auth.users u
left join public.profiles p on p.id = u.id;

create or replace view admin.learned_words as
select
  w.user_id,
  coalesce(p.name, '') as name,
  w.word_key,
  split_part(w.word_key, '|', 1) as word,
  w.learned_on,
  w.box,
  case when w.learned_on is null then 'seen'
       when w.box >= 5 then 'mastered'
       else 'learning' end as status,
  w.times_seen,
  w.times_correct,
  w.times_again,
  w.due as next_review
from public.word_progress w
left join public.profiles p on p.id = w.user_id;

create or replace view admin.hardest_words as
select
  word_key,
  split_part(word_key, '|', 1) as word,
  count(*) filter (where not knew_it) as times_missed,
  count(*)                            as times_answered,
  round(100.0 * count(*) filter (where not knew_it) / count(*), 1) as miss_rate_pct
from public.answer_events
group by word_key
having count(*) >= 5
order by miss_rate_pct desc;
