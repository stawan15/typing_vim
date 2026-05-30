#!/usr/bin/env bash
# deploy-local.sh — start postgres + cloudflared tunnel + Phoenix prod
# Idempotent: kills old processes, captures new tunnel URL, restarts everything.
set -euo pipefail

# ─── Paths & env ──────────────────────────────────────────────────────────
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TUNNEL_DIR="$PROJECT_ROOT/.tunnel"
ENV_FILE="$TUNNEL_DIR/env"
CF_LOG="$TUNNEL_DIR/cloudflared.log"
PHX_LOG="$TUNNEL_DIR/phoenix.log"

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

# Colours
c_g=$'\e[32m'; c_y=$'\e[33m'; c_r=$'\e[31m'; c_b=$'\e[34m'; c_dim=$'\e[2m'; c_0=$'\e[0m'
say()  { echo "${c_b}▶${c_0} $*"; }
ok()   { echo "${c_g}✓${c_0} $*"; }
warn() { echo "${c_y}!${c_0} $*"; }
die()  { echo "${c_r}✗${c_0} $*" >&2; exit 1; }

# ─── 0. Preconditions ─────────────────────────────────────────────────────
[[ -d "$PROJECT_ROOT" ]] || die "project root not found: $PROJECT_ROOT"
mkdir -p "$TUNNEL_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
  die "missing $ENV_FILE — was the app ever deployed? run setup first."
fi

command -v mix >/dev/null         || die "mix not on PATH — is mise activated?"
command -v cloudflared >/dev/null || die "cloudflared not on PATH — install to ~/.local/bin"

cd "$PROJECT_ROOT"

# ─── 1. Postgres ──────────────────────────────────────────────────────────
say "checking postgres..."
if pg_ctl -D "$HOME/.postgres-data" status >/dev/null 2>&1; then
  ok "postgres already running"
else
  say "starting postgres..."
  pg_ctl -D "$HOME/.postgres-data" -l "$HOME/.postgres-data/logfile" start >/dev/null
  sleep 2
  pg_ctl -D "$HOME/.postgres-data" status >/dev/null 2>&1 \
    || die "postgres failed to start — see $HOME/.postgres-data/logfile"
  ok "postgres started"
fi

# ─── 2. Stop old processes ────────────────────────────────────────────────
say "stopping previous phoenix + cloudflared..."
pkill -f "mix phx.server"                       2>/dev/null || true
pkill -f "cloudflared tunnel --url http://local" 2>/dev/null || true
sleep 2
ok "old processes stopped"

# ─── 3. Start cloudflared, capture URL ────────────────────────────────────
say "starting cloudflared tunnel..."
: > "$CF_LOG"
setsid nohup cloudflared tunnel --url http://localhost:4000 --no-autoupdate \
  > "$CF_LOG" 2>&1 < /dev/null &
disown
CF_PID=$!

URL=""
for i in $(seq 1 20); do
  sleep 1
  URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$CF_LOG" | head -1 || true)
  [[ -n "$URL" ]] && break
done

[[ -n "$URL" ]] || { tail -30 "$CF_LOG"; die "cloudflared failed to give a URL in 20s"; }
HOST="${URL#https://}"
ok "tunnel up: $URL"

# ─── 4. Persist PHX_HOST into env file ────────────────────────────────────
if grep -q '^PHX_HOST=' "$ENV_FILE"; then
  sed -i "s|^PHX_HOST=.*|PHX_HOST=$HOST|" "$ENV_FILE"
else
  echo "PHX_HOST=$HOST" >> "$ENV_FILE"
fi

# ─── 5. Load env + compile + migrate ──────────────────────────────────────
set -a; source "$ENV_FILE"; set +a

say "compiling (prod)..."
MIX_ENV=prod mix compile 2>&1 | tail -3

say "running migrations..."
unset PHX_SERVER  # don't start server during migrate
MIX_ENV=prod mix ecto.migrate 2>&1 | tail -3
export PHX_SERVER=true

# ─── 6. Start Phoenix ─────────────────────────────────────────────────────
say "starting phoenix..."
: > "$PHX_LOG"
setsid nohup mix phx.server > "$PHX_LOG" 2>&1 < /dev/null &
disown
PHX_PID=$!

# ─── 7. Smoke test ────────────────────────────────────────────────────────
say "waiting for phoenix to listen on :4000..."
ready=false
for i in $(seq 1 30); do
  sleep 1
  if ss -tln 2>/dev/null | grep -q ':4000 '; then
    ready=true; break
  fi
done
$ready || { tail -30 "$PHX_LOG"; die "phoenix did not start in 30s"; }
ok "phoenix listening on :4000"

say "smoke-testing public URL..."
code=$(/usr/bin/curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$URL/" || echo "000")
if [[ "$code" == "200" ]]; then
  ok "public URL returned $code"
else
  warn "public URL returned $code (may need a few more seconds — try again with status.sh)"
fi

# ─── 8. Report ────────────────────────────────────────────────────────────
echo
echo "${c_g}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${c_0}"
echo "  ${c_g}🚀 DEPLOYED${c_0}"
echo
echo "  URL:        ${c_y}$URL${c_0}"
echo "  Phoenix:    PID $(pgrep -f 'mix phx.server' | head -1 || echo '?') · log $PHX_LOG"
echo "  Cloudflared:PID $(pgrep -f 'cloudflared tunnel --url' | head -1 || echo '?') · log $CF_LOG"
echo
echo "  ${c_dim}status:${c_0} ./scripts/status.sh"
echo "  ${c_dim}stop:${c_0}   ./scripts/stop.sh"
echo "  ${c_dim}logs:${c_0}   tail -f $PHX_LOG"
echo "${c_g}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${c_0}"
