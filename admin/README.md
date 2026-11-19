# Hallo Leute admin dashboard

A single web page that shows every learner (guests included), their words,
daily activity, practice modes and the hardest words. It reads from Supabase
through admin-only functions, so only accounts in `public.admins` can see
anything.

## One-time setup

1. **Create your admin login** (no email sender needed):
   Supabase → **Authentication → Users → Add user → Create new user**.
   Enter your email and a strong password, and tick **Auto Confirm User**.
2. **Make it an admin**: Supabase → **SQL Editor**, then run
   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'you@example.com';
   ```
   Repeat both steps for Anoop.
3. **Config**: `admin/config.js` holds the project URL and the public
   publishable key (copy `config.example.js` if it's missing).

## Open it

Double-click `admin/index.html`, or serve the folder:

```bash
cd admin && python3 -m http.server 8090   # then open http://localhost:8090
```

To share it with the team, deploy the `admin/` folder to any static host
(Netlify, Vercel, GitHub Pages). It's safe: without an admin login it shows
nothing.

Admin accounts are hidden from the learner list and the totals.
