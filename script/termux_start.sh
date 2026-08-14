#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-3000}"

log()  { printf '\033[1;34m[+] %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

cd "$(dirname "$0")/.."

lan_ip() {
  ip -4 addr show scope global 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | grep -v '^127\.' | head -n1
}

write_env() {
  local ip
  ip=$(lan_ip)
  if [ -z "$ip" ]; then
    ip="127.0.0.1"
    warn "Could not detect LAN IP; set PUBLIC_HOST manually in .env.termux"
  fi
  cat > .env.termux <<EOF
export RACK_ENV=production
export PORT=$PORT
export PUBLIC_HOST=$ip
export PUBLIC_PORT=$PORT
export YOUTUBE_DL_PATH="$PWD/venv/bin/youtube-dl"
EOF
  log "Wrote .env.termux (PUBLIC_HOST=$ip)"
}

write_env
. ./.env.termux

log "Acquiring wake lock (keeps server alive with screen off)"
termux-wake-lock 2>/dev/null || warn "termux-wake-lock failed; server may pause when screen locks"

log "Starting server at http://${PUBLIC_HOST}:${PORT}"
exec bundle exec puma -b tcp://0.0.0.0:"${PORT}" config.ru