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

## Deploy to Fly.io + Neon (free tier)

1. Create a Postgres DB on [Neon](https://neon.tech) — copy the connection string.
2. Install [flyctl](https://fly.io/docs/hands-on/install-flyctl/) and `fly auth login`.
3. From the project root:

```bash
fly apps create typing-vim          # or pick your own name + update fly.toml
fly secrets set \
  DATABASE_URL='postgres://user:pass@host/db?sslmode=require' \
  SECRET_KEY_BASE="$(mix phx.gen.secret)" \
  PHX_HOST=typing-vim.fly.dev
fly deploy
```

After first deploy, seed the vim lessons:

```bash
fly ssh console -C "/app/bin/typing_vim eval 'Code.eval_file(\"/app/lib/typing_vim-0.1.0/priv/repo/seeds.exs\")'"
```

(or include a release task — see `lib/typing_vim/release.ex` if you add one.)

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
