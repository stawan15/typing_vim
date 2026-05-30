#!/usr/bin/env bash
# status.sh — show running state of postgres / cloudflared / phoenix + URL
set -u

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TUNNEL_DIR="$PROJECT_ROOT/.tunnel"
CF_LOG="$TUNNEL_DIR/cloudflared.log"
PHX_LOG="$TUNNEL_DIR/phoenix.log"

c_g=$'\e[32m'; c_y=$'\e[33m'; c_r=$'\e[31m'; c_dim=$'\e[2m'; c_0=$'\e[0m'

check() {
  local name="$1" pid="$2"
  if [[ -n "$pid" ]]; then
    printf "  %-13s ${c_g}✓ running${c_0}  PID %s\n" "$name" "$pid"
  else
    printf "  %-13s ${c_r}✗ stopped${c_0}\n" "$name"
  fi
}

echo "${c_y}━━━ typing_vim status ━━━${c_0}"

PG_PID=$(pg_ctl -D "$HOME/.postgres-data" status 2>/dev/null \
         | grep -oE 'PID: [0-9]+' | awk '{print $2}')
check "PostgreSQL" "${PG_PID:-}"

CF_PID=$(pgrep -f 'cloudflared tunnel --url http://localhost:4000' | head -1)
check "Cloudflared" "${CF_PID:-}"

PHX_PID=$(pgrep -f 'mix phx.server' | head -1)
check "Phoenix"     "${PHX_PID:-}"

PORT_OK=$(ss -tln 2>/dev/null | grep -c ':4000 ')
if [[ "$PORT_OK" -gt 0 ]]; then
  printf "  %-13s ${c_g}✓ listening${c_0}\n" "Port :4000"
else
  printf "  %-13s ${c_r}✗ not listening${c_0}\n" "Port :4000"
fi

URL=""
[[ -f "$CF_LOG" ]] && URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$CF_LOG" | head -1)

echo
if [[ -n "$URL" ]]; then
  echo "  URL:  ${c_y}$URL${c_0}"
else
  echo "  URL:  ${c_dim}(no tunnel URL found in log)${c_0}"
fi

if [[ -f "$PHX_LOG" ]]; then
  echo
  echo "  ${c_dim}── last 5 lines of phoenix.log ──${c_0}"
  tail -5 "$PHX_LOG" | sed 's/^/    /'
fi
