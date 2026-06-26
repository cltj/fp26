# FP26 Party App — Setup Guide

A complete party experience with login, QR-based interactions, live wall, music queue, and team scoreboard.

## Pages Overview

| Page | Purpose |
|------|---------|
| `index.html` | **Character Select** - Participants tap their photo and enter their PIN. QR codes point here. |
| `home.html` | **Dashboard** - After login, shows QR codes for music/submit, plus links to Wall & Scoreboard |
| `submit.html` | **Post to Wall** - Submit messages, photos, or videos |
| `music.html` | **Add Music** - Request songs for the playlist |
| `wall.html` | **The Wall** - Live feed of posts (project on big screen) |
| `scores.html` | **Scoreboard** - Team scores. Admin-only editing. |

---

## 1. Supabase Setup (10 minutes)

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

alter publication supabase_realtime add table posts;

create policy "Anyone can post"   on posts for insert with check (true);
create policy "Anyone can read"   on posts for select using (approved = true);
create policy "Anyone can update reactions" on posts for update using (true) with check (true);

alter table posts enable row level security;
```

### Create the `scores` table

```sql
create table scores (
  team_id     text primary key,
  scores      jsonb default '[null, null, null, null]'::jsonb,
  updated_at  timestamptz default now()
);

alter publication supabase_realtime add table scores;

create policy "Anyone can read scores" on scores for select using (true);
create policy "Anyone can update scores" on scores for update using (true);
create policy "Anyone can insert scores" on scores for insert with check (true);

alter table scores enable row level security;
```

### Create the `music_requests` table

```sql
create table music_requests (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz default now(),
  name        text not null,
  song        text not null,
  link        text
);

alter publication supabase_realtime add table music_requests;

create policy "Anyone can add music" on music_requests for insert with check (true);
create policy "Anyone can read music" on music_requests for select using (true);

alter table music_requests enable row level security;
```

### Create the `participants` table

```sql
create table participants (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  photo       text,
  pin         text not null,
  isAdmin     boolean default false
);

-- Insert your participants
insert into participants (name, photo, pin, isAdmin) values 
  ('TJ', 'tj.jpg', '1234', true),
  ('Eivind', 'eivind.jpeg', '5678', false),
  ('Helle', 'helle.jpeg', '9012', false);
-- Add more participants as needed

create policy "Anyone can read participants" on participants for select using (true);

alter table participants enable row level security;
```

### Create the storage bucket

Go to Storage → New bucket → name it `party-media` → set to **Public**.

Then add a policy on the bucket to allow uploads:
- Go to Storage → party-media → Policies → New policy
- For INSERT: allow `anon` role, no conditions.

---

## 2. Configure all HTML files

In `submit.html`, `music.html`, `wall.html`, and `scores.html`, find this block and fill in your values:

```js
const SUPABASE_URL      = 'https://YOUR_PROJECT.supabase.co'
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY'
```

Your URL and anon key are in Supabase → Project Settings → API.

---

## 3. Deploy to GitHub Pages

1. Create a new GitHub repo
2. Upload all HTML files to the repo root
3. Go to Settings → Pages → Source: Deploy from branch → main → / (root)
4. After a minute your site is live at `https://YOUR_USERNAME.github.io/YOUR_REPO/`

---

## 4. Generate the QR Code

Create a QR code pointing to your **index.html** (the login page):

```
https://YOUR_USERNAME.github.io/YOUR_REPO/index.html
```

Use https://qr.io or similar. Print and display at the party entrance.

---

## 5. On the Night

### For participants:
1. Scan QR code → lands on character select (`index.html`)
2. Tap their photo → enter their PIN → redirected to dashboard (`home.html`)
3. From dashboard: post messages, add music, view wall or scoreboard

### For admins:
1. **Admin taps their photo** → enters PIN → gets admin access (extra options visible)
2. Admin can:
   - Add/modify scores on the Scoreboard
   - Moderate posts on The Wall (approve/delete)

### Display setup:
- Open `wall.html` on a laptop connected to TV/projector
- Posts appear in real-time as participants submit

---

## Participants & PINs

Participants are stored in Supabase in the `participants` table. Each participant has:
- `name`: Display name
- `photo`: Filename of their photo (e.g., `tj.jpg`)
- `pin`: Their personal PIN code to log in
- `isAdmin`: If `true`, they see admin options (scoring, moderation)

To add/edit participants:
1. Go to Supabase → Table Editor → `participants`
2. Add rows with name, photo filename, pin, and isAdmin flag

---

## Optional: Enable Moderation

In both `submit.html` and `wall.html` change:
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
