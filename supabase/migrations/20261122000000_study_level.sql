-- CEFR levels: the level a learner is studying now (A1–B2), synced with
-- the profile. Null until chosen (the app then follows profiles.level).
alter table public.profiles
  add column study_level text
  check (study_level in ('a1', 'a2', 'b1', 'b2'));

comment on column public.profiles.level is 'Setup answer: a0 | a1 | a2 | b1 | b2';
comment on column public.profiles.study_level is 'Level being studied: a1 | a2 | b1 | b2';
