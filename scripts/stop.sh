#!/usr/bin/env bash
# stop.sh — kill phoenix + cloudflared for this project (postgres left running)
set -u

c_g=$'\e[32m'; c_y=$'\e[33m'; c_dim=$'\e[2m'; c_0=$'\e[0m'

echo "${c_y}stopping typing_vim processes...${c_0}"

if pkill -f 'mix phx.server' 2>/dev/null; then
  echo "${c_g}✓${c_0} phoenix stopped"
else
  echo "${c_dim}·${c_0} phoenix was not running"
fi

if pkill -f 'cloudflared tunnel --url http://localhost:4000' 2>/dev/null; then
  echo "${c_g}✓${c_0} cloudflared stopped"
else
  echo "${c_dim}·${c_0} cloudflared was not running"
fi

echo
echo "${c_dim}postgres is still running (use \`pgstop\` to stop it too)${c_0}"
