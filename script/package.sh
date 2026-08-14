#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

BLUE=$'\033[1;34m'
GREEN=$'\033[1;32m'
RESET=$'\033[0m'

OUT="einthusanlib.tar.gz"
PHONE_IP=""

usage() {
  cat <<'EOF'
Usage:
  bash script/package.sh                  # package + interactive transfer menu
  bash script/package.sh --scp <phone-ip>  # package + scp to the phone, no prompts
EOF
}

if [ "${1:-}" = "--scp" ]; then
  PHONE_IP="${2:-}"
  if [ -z "$PHONE_IP" ]; then
    usage
    exit 1
  fi
elif [ $# -gt 0 ]; then
  usage
  exit 1
fi

git archive --format=tar.gz -o "$OUT" HEAD
printf '\033[1;34m[+] Created %s (%s)\033[0m\n' "$OUT" "$(du -h "$OUT" | cut -f1)"

phone_steps() {
  cat <<EOF

${BLUE}[+] On the phone:${RESET}
  tar xzf $OUT && cd einthusanlib
  bash script/termux_setup.sh    # install deps, gems, prepare the app (run once)
  bash script/termux_start.sh    # serve on http://<phone-ip>:3000
EOF
}

usb_steps() {
  cat <<EOF

${BLUE}[+] USB / Downloads:${RESET}
  1. Copy $OUT into the phone's Downloads folder (USB cable or cloud).
  2. In Termux, run once: termux-setup-storage   (grants storage permission)
  3. Then: cp ~/storage/downloads/$OUT ~/
EOF
}

scp_transfer() {
  local target="$1"
  printf "${BLUE}[+] Transferring to %s via scp (Termux sshd, port 8022)${RESET}\n" "$target"
  scp -P 8022 "$OUT" "$target":
  printf "${GREEN}[+] Transfer complete.${RESET}\n"
  phone_steps
}

if [ -n "$PHONE_IP" ]; then
  scp_transfer "$PHONE_IP"
  exit 0
fi

cat <<EOF
${BLUE}[+] How do you want to transfer to the phone?${RESET}
  1) scp (Termux sshd, port 8022)    2) USB / Downloads    3) skip
EOF
printf 'Choice [1-3]: '
read -r choice

case "$choice" in
  1)
    printf 'Phone (IP or user@ip, e.g. 192.168.1.5): '
    read -r PHONE_IP
    if [ -z "$PHONE_IP" ]; then
      printf 'No phone given.\n' >&2
      exit 1
    fi
    scp_transfer "$PHONE_IP"
    ;;
  2)
    usb_steps
    phone_steps
    ;;
  3)
    printf 'Skipping transfer.\n'
    phone_steps
    ;;
  *)
    printf 'Invalid choice.\n' >&2
    exit 1
    ;;
esac