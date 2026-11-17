-- Practice modes on answers + admin dashboard access.

-- ───────────────────── how each answer was practised ─────────────────────
alter table public.answer_events
  add column mode text not null default 'flashcard'
  check (mode in ('flashcard', 'article', 'meaning', 'listening', 'spelling'));
create index answer_events_mode_idx on public.answer_events (mode);

-- ───────────────────────────── admins ─────────────────────────────
-- Team members allowed to use the admin dashboard. Add yourself after
-- signing in to the dashboard once (see admin/README.md):
--   insert into public.admins (user_id)
--   select id from auth.users where email = 'you@example.com';
create table public.admins (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  added_at   timestamptz not null default now()
);
-- RLS on with no policies: nobody can read or change it through the API.
alter table public.admins enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- Every report below checks is_admin() first.
create or replace function public._require_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
end;
$$;
revoke all on function public._require_admin() from public, anon, authenticated;

-- Headline numbers.
create or replace function public.admin_overview()
returns json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare result json;
begin
  perform public._require_admin();
  select json_build_object(
    'learners',        (select count(*) from auth.users u
                          where not exists (select 1 from public.admins a where a.user_id = u.id)),
    'guests',          (select count(*) from auth.users u where u.is_anonymous),
    'saved_accounts',  (select count(*) from auth.users u
                          where not u.is_anonymous
                            and not exists (select 1 from public.admins a where a.user_id = u.id)),
    'active_today',    (select count(distinct user_id) from public.daily_activity where day = current_date),
    'active_7d',       (select count(distinct user_id) from public.daily_activity where day > current_date - 7),
    'words_learned',   (select count(*) from public.word_progress where learned_on is not null),
    'words_mastered',  (select count(*) from public.word_progress where box >= 5),
    'answers_7d',      (select count(*) from public.answer_events where answered_at > now() - interval '7 days')
  ) into result;
  return result;
end;
$$;

-- Activity per day.
create or replace function public.admin_daily(days integer default 30)
returns table (day date, active_learners bigint, new_words bigint, reviews bigint, misses bigint)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public._require_admin();
  return query
    select d.day, count(distinct d.user_id), sum(d.new_words)::bigint,
           sum(d.reviews)::bigint, sum(d.again)::bigint
    from public.daily_activity d
    where d.day > current_date - days
    group by d.day
    order by d.day;
end;
$$;

-- All learners with totals.
create or replace function public.admin_learners()
returns table (
  user_id uuid, name text, email text, is_guest boolean, level text,
  daily_goal text, joined_at timestamptz, words_learned bigint,
  words_mastered bigint, total_answers bigint, last_active timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public._require_admin();
  return query
    select l.user_id, l.name, l.email::text, l.is_guest, l.level, l.daily_goal,
           l.joined_at, l.words_learned, l.words_mastered, l.total_answers,
           l.last_active
    from admin.learners l
    where not exists (select 1 from public.admins a where a.user_id = l.user_id)
    order by l.last_active desc nulls last, l.joined_at desc;
end;
$$;

-- One learner's words.
create or replace function public.admin_learner_words(target uuid)
returns table (
  word text, status text, learned_on date, times_seen integer,
  times_correct integer, times_again integer, next_review date
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public._require_admin();
  return query
    select w.word, w.status, w.learned_on, w.times_seen, w.times_correct,
           w.times_again, w.next_review
    from admin.learned_words w
    where w.user_id = target
    order by w.learned_on desc nulls last;
end;
$$;

-- Words learners miss most.
create or replace function public.admin_hardest(lim integer default 30)
returns table (word text, times_missed bigint, times_answered bigint, miss_rate_pct numeric)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public._require_admin();
  return query
    select h.word, h.times_missed, h.times_answered, h.miss_rate_pct
    from admin.hardest_words h
    order by h.miss_rate_pct desc, h.times_answered desc
    limit lim;
end;
$$;

-- Answers per practice mode (last 30 days).
create or replace function public.admin_modes()
returns table (mode text, answers bigint, correct_pct numeric)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public._require_admin();
  return query
    select e.mode, count(*),
           round(100.0 * count(*) filter (where e.knew_it) / count(*), 1)
    from public.answer_events e
    where e.answered_at > now() - interval '30 days'
    group by e.mode
    order by count(*) desc;
end;
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'admin_overview()', 'admin_daily(integer)', 'admin_learners()',
    'admin_learner_words(uuid)', 'admin_hardest(integer)', 'admin_modes()'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
