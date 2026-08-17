#!/usr/bin/env bash
set -euo pipefail

log() { printf '\033[1;34m[+] %s\033[0m\n' "$*"; }

cd "$(dirname "$0")/.."

install_packages() {
  log "Updating Termux package lists"
  pkg update -y
  log "Installing packages: ruby python zlib clang make binutils pkg-config iproute2 aria2"
  pkg install -y ruby python zlib clang make binutils pkg-config iproute2 aria2
}

setup_venv() {
  if [ ! -d venv ]; then
    log "Creating Python virtualenv"
    python -m venv venv
  fi
  log "Installing youtube-dl into venv"
  venv/bin/pip install --upgrade youtube-dl
}

setup_gems() {
  log "Configuring bundler (vendor path, no dev/test gems)"
  bundle config set path vendor/bundle
  bundle config set without 'development test'
  log "Installing gems (Sinatra + puma; compiles native extensions, may take a few minutes)"
  bundle install
}

install_packages
setup_venv
setup_gems
log "Setup complete. Run script/termux_start.sh to start the server."