-- Time spent learning per day (lessons + practice), for the "This week" view.
alter table public.daily_activity
  add column study_seconds integer not null default 0;
