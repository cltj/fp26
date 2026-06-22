# Party Wall — Setup Guide

Two files: `submit.html` (guests scan QR → this page) and `wall.html` (you project this on a TV).

---

## 1. Supabase setup (5 minutes)

### Create the `posts` table

Go to your Supabase project → SQL Editor → paste and run:

```sql
create table posts (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz default now(),
  name        text not null,
  message     text,
  type        text default 'complaint',
  media_url   text,
  media_type  text,
  approved    boolean default true,
  reactions   jsonb default '{}'::jsonb
);

-- Enable realtime
alter publication supabase_realtime add table posts;

-- Allow anyone to insert and read approved posts (public event)
create policy "Anyone can post"   on posts for insert with check (true);
create policy "Anyone can read"   on posts for select using (approved = true);
create policy "Anyone can update reactions" on posts for update using (true) with check (true);

alter table posts enable row level security;
```

### Create the storage bucket

Go to Storage → New bucket → name it `party-media` → set to **Public**.

Then add a policy on the bucket to allow uploads:
- Go to Storage → party-media → Policies → New policy
- For INSERT: allow `anon` role, no conditions.

---

## 2. Configure both HTML files

In both `submit.html` and `wall.html`, find this block near the bottom and fill in your values:

```js
const SUPABASE_URL      = 'https://YOUR_PROJECT.supabase.co'
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY'
```

Your URL and anon key are in Supabase → Project Settings → API.

In `wall.html` also update:
```js
const SUBMIT_URL = 'https://YOUR_USERNAME.github.io/YOUR_REPO/submit.html'
```

---

## 3. Deploy to GitHub Pages

1. Create a new GitHub repo (can be private or public)
2. Upload both HTML files to the repo root
3. Go to Settings → Pages → Source: Deploy from branch → main → / (root)
4. After a minute your site is live at `https://YOUR_USERNAME.github.io/YOUR_REPO/`

---

## 4. Generate the QR code

Go to https://www.qr-code-generator.com or https://qr.io and paste:

```
https://YOUR_USERNAME.github.io/YOUR_REPO/submit.html
```

Download the QR code image. At the party you can:
- Show it on screen via the "Show QR" button in the wall header
- Print it and put it on tables

---

## 5. On the night

- Open `wall.html` on a laptop connected to the TV
- Guests scan the QR → open `submit.html` on their phones
- Posts appear on the wall in real-time
- Click **Moderate** to approve/delete posts before they appear (set `MODERATION = true` in both files first)

---

## Optional: enable moderation

In both files change:
```js
const MODERATION = false  →  const MODERATION = true
```

Also update the SQL policy so guests can't read unapproved posts, but the wall admin can:

```sql
-- Drop the open read policy first
drop policy "Anyone can read" on posts;

-- Only approved posts are public
create policy "Public reads approved" on posts for select using (approved = true);
```

New posts go into a queue. Use the **Moderate** panel on the wall page to approve them.

---

## Post types

| Type | Emoji | Use |
|------|-------|-----|
| Complaint | 😤 | Classic party complaints |
| Cheer | 🙌 | Compliments and kudos |
| Chaos | 🔥 | Anything goes |

To change types, edit the `type-grid` buttons in `submit.html` and the `typeConfig` object in `wall.html`.