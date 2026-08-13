# Einthusanlib

A modern Ruby on Rails web application that fetches, downloads, and streams movies from Einthusan with real-time progress updates.

## ⚠️ Disclaimer

This application is for educational and personal use only. Users are responsible for complying with applicable laws and the terms of service of content providers. The authors are not responsible for any misuse of this software.

## Development

The project uses [mise](https://mise.jdx.dev) to manage the Ruby and Python toolchains and a Python virtualenv. Install mise (e.g. `brew install mise`), then activate it in your shell (see the mise docs for your shell).

```
mise install        # installs ruby 3.2.3, python 3.11, and the dev tools (pre-commit, gitleaks, trufflehog, semgrep)
mise run setup      # creates venv, installs youtube-dl, gems, prepares the db, and registers pre-commit hooks
bin/rails server
```

`mise run setup` is idempotent, so you can re-run it any time to bring your environment up to date. The first run creates the Python virtualenv at `venv/` from the mise-managed python and installs `youtube-dl` into it.

### Pre-commit hooks

`mise run setup` registers git hooks that run on every commit: **gitleaks** and **trufflehog** scan for leaked secrets, and **semgrep** runs security-focused static analysis (the `p/auto` ruleset). Any finding blocks the commit. To skip the hooks for a commit (use sparingly): `git commit --no-verify`.

### Running tests

```
bin/rails test           # full suite
bin/rails test test/services  # just services
bin/rubocop              # style check (must stay clean)
```

The suite is integration/unit tests only — no browser/system tests (the Stimulus/Turbo glue is thin and untested, a deliberate tradeoff). No Chrome or driver gems are needed; CI runs `bin/rails test` directly.

## Production

Bare-metal setup for a low-resource, headless Linux box (no Docker). The app is SQLite-backed (Solid Cache and Solid Cable included), so no extra services like Redis are needed.

### Prerequisites

1. **Install Ruby 3.2.3** (the version pinned in `mise.toml`) using your environment's preferred method, then verify with `ruby -v`.
2. **Install system packages** `python3`, `python3-venv`, and `sqlite3` using your package manager.

### Install

```sh
git clone <this-repo> einthusanlib
cd einthusanlib

python3 -m venv venv
venv/bin/pip install youtube-dl

bundle config set without 'development test'
bundle install
```

### Configure

1. Point the app at your host and port. Edit `config/environments/production.rb` and replace the hardcoded `104.248.124.144:81` in `default_url_options`, `action_cable.url`, and `action_cable.allowed_request_origins` with your own address.
2. Export the environment (or add it to your shell profile):

```sh
export RAILS_ENV=production
export YOUTUBE_DL_PATH="$PWD/venv/bin/youtube-dl"
```

No `SECRET_KEY_BASE` or `RAILS_MASTER_KEY` is needed — if unset, the session secret is generated once and persisted to `storage/.secret_key_base`, and the app never reads encrypted credentials.

### Prepare and run

```sh
bin/rails db:prepare
bin/rails assets:precompile

bin/rails server -b 0.0.0.0 -p 3000
```

Run on a high port (no root required) and background it however your environment prefers.
