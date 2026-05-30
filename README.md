# typing_vim

A MonkeyType-style typing test **plus** a Vim shortcut practice trainer — built with Phoenix LiveView, real-time online counter via `Phoenix.Presence`, guest mode (no signup), dark-only theme, sound effects, and a public leaderboard.

## Features

- **Typing mode** (`/type`): time (15/30/60/120s) or words modes, live WPM + accuracy, optional save to leaderboard
- **Vim mode** (`/vim`): real CodeMirror 6 editor with the `@replit/codemirror-vim` plugin, 15 starter lessons (motion, delete, change, yank, insert, replace), hints
- **Leaderboard** (`/leaderboard`): filterable by mode + duration
- **Online counter**: live user count via `Phoenix.Presence`, shown in header
- **Mobile aware**: Vim lessons are hidden on mobile (requires physical keyboard)
- **Sound effects**: mechanical keyboard click on each keystroke (Web Audio API, no asset download)
- **Guest mode**: stable per-browser `guest_id` stored in signed session cookie — no signup needed

## Local development

Requires: Elixir 1.16+, Erlang 26+, Node 20+, PostgreSQL 16+.

```bash
mix setup
mix phx.server
# open http://localhost:4000
```

## Deploy — FREE (no credit card required)

### Option A: Gigalixir ⭐ recommended

Gigalixir is built for Elixir/Phoenix. Free tier: 1 app + 1 free Postgres (10k rows / 2GB), **no credit card required**.

#### 1. Install the Gigalixir CLI (one-time)

```bash
pip3 install gigalixir --user
# or: sudo apt install python3-pip && pip3 install gigalixir --user
```

#### 2. Sign up + login

```bash
gigalixir signup            # email + password — no credit card
gigalixir login
```

#### 3. Create app + Postgres

```bash
cd ~/typing_vim
gigalixir create -n typing-vim-stawan15
# attach gigalixir's free postgres (sets DATABASE_URL automatically)
gigalixir pg:create --free
```

#### 4. Set required secrets

```bash
gigalixir config:set SECRET_KEY_BASE="$(mix phx.gen.secret)"
gigalixir config:set PHX_HOST="typing-vim-stawan15.gigalixirapp.com"
gigalixir config:set POOL_SIZE=2     # free tier has limited connections
```

#### 5. Deploy (just git push!)

```bash
git push gigalixir develop:master
```

Gigalixir builds, deploys, and exposes the app at `https://<your-app>.gigalixirapp.com`.

#### 6. Run migrations + seeds after first deploy

```bash
gigalixir ps:migrate
gigalixir run -- mix run priv/repo/seeds.exs
```

#### 7. Open it

```bash
gigalixir open
```

---

### Option B: Render (also free, sleeps after 15min)

1. Push code to GitHub (already done)
2. Sign up at https://render.com (GitHub OAuth, no CC for free web service)
3. New → Web Service → connect repo → use Docker (auto-detects `Dockerfile`)
4. Add Postgres add-on (free) — set `DATABASE_URL` env var
5. Set `SECRET_KEY_BASE` and `PHX_HOST` env vars
6. Deploy

Free Render service sleeps after 15 min of no traffic (~30s cold start).

---

### Option C: Fly.io (requires credit card)

See `fly.toml` and `Dockerfile` in this repo — but Fly now requires a credit card for verification (free tier still exists, just need the card on file).

## Project layout

```
lib/typing_vim/             contexts: Typing, Vim
lib/typing_vim_web/live/    HomeLive, TypingLive, LeaderboardLive, VimIndexLive, VimLessonLive
lib/typing_vim_web/presence.ex   online tracking
assets/js/typing_engine.js  client-side typing engine
assets/js/vim_editor.js     CodeMirror 6 + vim mode
assets/js/sound.js          Web Audio key click + success/error
priv/wordlists/             english word list
priv/repo/seeds.exs         vim lessons
```
