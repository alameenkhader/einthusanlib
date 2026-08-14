#!/usr/bin/env bash
set -euo pipefail

log() { printf '\033[1;34m[+] %s\033[0m\n' "$*"; }

cd "$(dirname "$0")/.."

install_packages() {
  log "Updating Termux package lists"
  pkg update -y
  log "Installing packages: ruby python sqlite zlib clang make binutils pkg-config iproute2 aria2"
  pkg install -y ruby python sqlite zlib clang make binutils pkg-config iproute2 aria2
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
  log "Installing gems (Sinatra + ActiveRecord + sqlite3; compiles native extensions, may take a few minutes)"
  bundle install
}

prepare_app() {
  log "Preparing database"
  RACK_ENV=production bundle exec rake db:prepare
}

smoke_check() {
  log "Verifying production boot and SQLite connection"
  RACK_ENV=production bundle exec ruby -e \
    'require_relative "config/boot"; abort "SQLite connection failed" unless ActiveRecord::Base.connection.active?'
}

install_packages
setup_venv
setup_gems
prepare_app
smoke_check
log "Setup complete. Run script/termux_start.sh to start the server."