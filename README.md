# typing_vim

A MonkeyType-style typing test **plus** a Vim shortcut practice trainer — built with Phoenix LiveView. Real-time online counter via `Phoenix.Presence`, guest mode (no signup), dark-only theme, terminal-styled vim editor with live progress, and a public leaderboard.

## Features

### Typing mode (`/type`)
- Time-based (15 / 30 / 60 / 120s) **or** word-count modes
- Live WPM + accuracy as you type
- Optional save to public leaderboard

### Vim practice (`/vim`)
- **51 lessons** across 11 categories — motion, delete, change, yank, insert, replace, visual, advanced, regex, ex commands, refactor
- Difficulty 1–5 (easy fundamentals → macros, regex captures, `:g`/`:v` global commands, line-number expressions, multi-line refactors)
- Real CodeMirror 6 editor + `@replit/codemirror-vim` plugin
- **Gruvbox-dark terminal theme** with line numbers, fat block cursor, live status line
- **Live progress bar** — character-level diff against target, updates as you type
- **Live status bar** — current mode (`-- NORMAL/INSERT/VISUAL --`), keystrokes counter, elapsed time, `current/expected` char count, progress %
- **Auto-check** — solution detected the moment your buffer matches target (no explicit "submit")
- **Keyboard-only navigation** — never touch the mouse:

  | Command | Shortcut | Action |
  |---|---|---|
  | `:w` | — | check / save |
  | `:n` | `gn` | next lesson |
  | `:p` / `:N` | `gp` | previous lesson |
  | `:r` | `gr` | reset buffer |
  | `:h` | `gh` | toggle hint |
  | `:q` | `gq` | back to lesson list |
  | `:wq` | — | check + next (combo) |

  Real ex commands defined via `Vim.defineEx()` + normal-mode mappings via `Vim.map()` — works exactly like vim.

### Leaderboard (`/leaderboard`)
- Filter by mode + duration

### Platform
- **Online counter** — live user count via `Phoenix.Presence`, shown in header
- **Mobile aware** — Vim lessons hidden on mobile (requires physical keyboard)
- **Sound effects** — mechanical keyboard click + success/error chimes via Web Audio API (no asset download)
- **Guest mode** — stable per-browser `guest_id` in signed session cookie, no signup

## Tech stack

- Elixir 1.16.3 / Erlang 26.2.5 / Phoenix 1.8.7 / LiveView
- PostgreSQL 18.3 (via [mise](https://mise.jdx.dev))
- Tailwind CSS v4 + daisyUI (dark theme only)
- CodeMirror 6 + `@replit/codemirror-vim`
- `Req` for HTTP (per AGENTS.md)

## Local development

Requires: Elixir 1.16+, Erlang 26+, Node 20+, PostgreSQL 16+ (recommended: install with [mise](https://mise.jdx.dev)).

```bash
mix setup            # deps + db.create + db.migrate + seeds + assets.setup
mix phx.server       # serves http://localhost:4000
```

Run tests + format + compile-with-warnings-as-errors before committing:

```bash
mix precommit
```

## Deploy

### 🥇 Cloudflare Tunnel (truly free, no credit card)

Most managed Phoenix hosts (Fly.io, Render, Gigalixir) now require a credit card. Cloudflare Tunnel is the only fully-free, no-card option — exposes a localhost Phoenix instance on a real `https://` URL.

**Trade-off:** the app is online only while your machine runs the Phoenix + cloudflared processes.

#### 1. Install the `cloudflared` binary (one-time)

```bash
mkdir -p ~/.local/bin
curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o ~/.local/bin/cloudflared
chmod +x ~/.local/bin/cloudflared
```

#### 2. Build assets + create prod DB

```bash
export MIX_ENV=prod
mix deps.get --only prod
mix compile
cd assets && npm install --no-audit --no-fund && cd ..
mix assets.deploy

# create local prod DB
psql -h localhost -U postgres -c "CREATE DATABASE typing_vim_prod"
```

#### 3. Set env vars + migrate + seed

```bash
export PHX_SERVER=true
export MIX_ENV=prod
export DATABASE_URL="ecto://postgres:postgres@localhost/typing_vim_prod"
export DATABASE_SSL=false                       # local pg has no SSL
export SECRET_KEY_BASE="$(mix phx.gen.secret)"
export PORT=4000
export POOL_SIZE=5

# (PHX_HOST is set after we know the tunnel URL — see step 5)

mix ecto.migrate
unset PHX_SERVER && mix run priv/repo/seeds.exs && export PHX_SERVER=true
```

#### 4. Start the tunnel — read the public URL from its log

```bash
cloudflared tunnel --url http://localhost:4000 --no-autoupdate > /tmp/cf.log 2>&1 &
sleep 5
grep trycloudflare.com /tmp/cf.log
# → https://<random-words>.trycloudflare.com
```

#### 5. Re-export `PHX_HOST` to that URL, then start Phoenix

```bash
export PHX_HOST="<random-words>.trycloudflare.com"      # no scheme
mix phx.server
```

Open the tunnel URL in your browser. The app runs locally, Cloudflare proxies it over HTTPS.

**Persistent URL** (instead of a random `trycloudflare.com`): create a free Cloudflare account, run `cloudflared tunnel login`, then `cloudflared tunnel create typing-vim` and route a custom DNS record. See [Cloudflare docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/).

### 🥈 Other options (require credit card)

| Provider | Free tier? | Credit card? |
|---|---|---|
| [Fly.io](https://fly.io) | yes | yes |
| [Render](https://render.com) | yes (sleeps after 15min) | yes |
| [Gigalixir](https://gigalixir.com) | yes | yes (as of 2026) |
| [Oracle Cloud Always Free](https://www.oracle.com/cloud/free/) | yes (4 ARM CPU, 24GB RAM, never sleeps) | yes (verify only) |

`Dockerfile`, `fly.toml`, and `lib/typing_vim/release.ex` are included for any container-based deploy. Gigalixir buildpack configs (`elixir_buildpack.config`, `phoenix_static_buildpack.config`, `compile`, `Procfile`) are also kept in repo.

## Project layout

```
lib/typing_vim/                 contexts: Typing, Vim, Release (prod migrate task)
lib/typing_vim_web/live/        HomeLive, TypingLive, LeaderboardLive,
                                VimIndexLive, VimLessonLive
lib/typing_vim_web/presence.ex  Phoenix.Presence — online tracking
lib/typing_vim_web/plugs/       guest_id session cookie plug
assets/js/typing_engine.js      client-side typing engine
assets/js/vim_editor.js         CodeMirror 6 + vim mode + custom :ex commands
assets/js/sound.js              Web Audio key click + success/error chimes
priv/wordlists/                 english_1k.json
priv/repo/seeds.exs             51 vim lessons (motion, delete, change, yank,
                                insert, replace, visual, advanced, regex, ex,
                                refactor)
```

## Environment variables (prod)

| Var | Required | Notes |
|---|---|---|
| `SECRET_KEY_BASE` | ✅ | `mix phx.gen.secret` |
| `DATABASE_URL` | ✅ | `ecto://user:pass@host/db` |
| `DATABASE_SSL` | optional | `false` for local pg, default `true` (e.g. Neon) |
| `PHX_HOST` | ✅ | public hostname (no scheme) |
| `PORT` | optional | default `4000` |
| `POOL_SIZE` | optional | default `10` |
| `PHX_SERVER` | for `mix phx.server` | set to `true` to actually start the listener |
