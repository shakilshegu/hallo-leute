-- Rate & suggest: learners rate the app (1–5) and say what to improve.
-- Learners can only add their own feedback; nobody but admins can read it
-- (through admin_feedback()). Feedback is deleted with the account.

create table public.feedback (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  rating      smallint not null check (rating between 1 and 5),
  improve     text check (char_length(improve) <= 1000),
  likes       text check (char_length(likes) <= 1000),
  app_version text check (char_length(app_version) <= 40),
  platform    text check (char_length(platform) <= 40),
  created_at  timestamptz not null default now()
);

create index feedback_user_idx on public.feedback (user_id);
create index feedback_created_idx on public.feedback (created_at desc);

alter table public.feedback enable row level security;
revoke all on public.feedback from anon;

-- Insert only: no select, update or delete policies for learners.
create policy "add own feedback" on public.feedback
  for insert to authenticated
  with check (user_id = (select auth.uid()));

-- Newest first, with who sent it.
create or replace function public.admin_feedback()
returns table (
  id uuid, user_id uuid, name text, email text, is_guest boolean,
  level text, rating smallint, improve text, likes text,
  app_version text, platform text, created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public._require_admin();
  return query
    select f.id, f.user_id, l.name, l.email::text, l.is_guest, l.level,
           f.rating, f.improve, f.likes, f.app_version, f.platform,
           f.created_at
    from public.feedback f
    left join admin.learners l on l.user_id = f.user_id
    order by f.created_at desc;
end;
$$;

revoke all on function public.admin_feedback() from public, anon;
grant execute on function public.admin_feedback() to authenticated;
