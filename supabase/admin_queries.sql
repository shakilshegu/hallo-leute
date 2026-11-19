-- Handy queries for the Hallo Leute team.
-- Paste into Supabase → SQL Editor. Replace the example values.

-- 1. Every learner with their totals (guests included), most active first.
select * from admin.learners order by last_active desc nulls last;

-- 2. Which words one learner has learned (find the user_id in query 1).
select word, status, learned_on, times_seen, times_correct, times_again, next_review
from admin.learned_words
where user_id = '00000000-0000-0000-0000-000000000000'
order by learned_on desc nulls last;

-- 3. A learner's full answer history.
select answered_at, split_part(word_key, '|', 1) as word, knew_it, review
from public.answer_events
where user_id = '00000000-0000-0000-0000-000000000000'
order by answered_at desc;

-- 4. Daily activity for the last 30 days (all learners).
select day, count(distinct user_id) as active_learners,
       sum(new_words) as new_words, sum(reviews) as reviews, sum(again) as misses
from public.daily_activity
where day > current_date - 30
group by day order by day desc;

-- 5. Words learners find hardest (at least 5 answers).
select * from admin.hardest_words limit 50;

-- 6. Guests vs. signed-in learners.
select is_guest, count(*) as learners, round(avg(words_learned), 1) as avg_words
from admin.learners group by is_guest;
