#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-3000}"

log()  { printf '\033[1;34m[+] %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

cd "$(dirname "$0")/.."

log "termux_start.sh (PORT=$PORT)"

lan_ip() {
  local ip=""
  ip="$(ip route get 8.8.8.8 2>/dev/null \
        | awk '/src/{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')" || true
  if [ -z "$ip" ]; then
    ip="$(python -c 'import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    s.connect(("8.8.8.8", 80))
    print(s.getsockname()[0])
except Exception:
    pass' 2>/dev/null | grep -v '^127\.')" || true
  fi
  if [ -z "$ip" ]; then
    ip="$(ip -4 addr show scope global 2>/dev/null \
            | awk '/inet /{print $2}' | cut -d/ -f1 | grep -v '^127\.' | head -n1)" || true
  fi
  if [ -z "$ip" ]; then
    ip="$(getprop dhcp.wlan0.ipaddress 2>/dev/null)" || true
  fi
  if [ -z "$ip" ]; then
    ip="$(getprop dhcp.wlan1.ipaddress 2>/dev/null)" || true
  fi
  printf '%s\n' "$ip"
}

public_ip() {
  python -c 'import urllib.request
print(urllib.request.urlopen("https://api.ipify.org", timeout=5).read().decode().strip())' 2>/dev/null || true
}

write_env() {
  local ip
  ip=$(lan_ip)
  if [ -z "$ip" ]; then
    ip="127.0.0.1"
    warn "Could not detect LAN IP; set PUBLIC_HOST manually in .env.termux"
    {
      command -v ip || printf '  (ip command not found - is iproute2 installed?)\n'
      python -c 'import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    s.connect(("8.8.8.8", 80))
    print("  udp-src:", s.getsockname()[0])
except Exception as e:
    print("  udp-src: error:", e)' 2>/dev/null || true
      getprop dhcp.wlan0.ipaddress 2>/dev/null || true
    } | while IFS= read -r line; do warn "$line"; done
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

public_ip=$(public_ip)
if [ -n "$public_ip" ]; then
  log "Public (WAN) address: http://${public_ip}:${PORT} (externally reachable only with port forwarding)"
else
  warn "Could not determine public IP (offline?); LAN access still works."
fi

log "Acquiring wake lock (keeps server alive with screen off)"
termux-wake-lock 2>/dev/null || warn "termux-wake-lock failed; server may pause when screen locks"

log "LAN address: http://${PUBLIC_HOST}:${PORT}"
if [ "$PUBLIC_HOST" = "127.0.0.1" ]; then
  warn "localhost-only mode: connect the phone and computer to the same Wi-Fi to access via LAN."
fi
exec bundle exec puma -b tcp://0.0.0.0:"${PORT}" config.ru