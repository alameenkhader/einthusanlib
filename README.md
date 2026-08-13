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

## Running on Termux (Android)

```
bash script/termux_setup.sh   # install deps, gems, and prepare the app (run once)
bash script/termux_start.sh   # start the server on your LAN at http://<phone-ip>:3000
```
