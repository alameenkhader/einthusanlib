# Einthusanlib

A lightweight Ruby web app that fetches, downloads, and streams movies from Einthusan. Built on Sinatra + standalone ActiveRecord + SQLite with a pure-Ruby HTML parser (oga) — no Rails, no nokogiri — and progress updates via simple polling.

## ⚠️ Disclaimer

This application is for educational and personal use only. Users are responsible for complying with applicable laws and the terms of service of content providers. The authors are not responsible for any misuse of this software.

## Development

The project uses [mise](https://mise.jdx.dev) to manage the Ruby and Python toolchains and a Python virtualenv. Install mise (e.g. `brew install mise`), then activate it in your shell (see the mise docs for your shell).

```
mise install        # installs ruby 3.2.3, python 3.11, and the dev tools (pre-commit, gitleaks, trufflehog, semgrep)
mise run setup      # creates venv, installs youtube-dl, gems, prepares the db, and registers pre-commit hooks
bundle exec puma    # starts the server on http://localhost:3000
```

`mise run setup` is idempotent, so you can re-run it any time to bring your environment up to date. The first run creates the Python virtualenv at `venv/` from the mise-managed python and installs `youtube-dl` into it.

The downloader uses [aria2c](https://aria2.github.io) (multi-connection) when available — the Einthusan CDN throttles single connections to ~10-25 KiB/s, but 16 parallel connections sustain ~2 MB/s. On macOS install it with `brew install aria2`; on Termux it's included in `script/termux_setup.sh`. Without aria2c the app falls back to a plain youtube-dl download.

### Pre-commit hooks

`mise run setup` registers git hooks that run on every commit: **gitleaks** and **trufflehog** scan for leaked secrets, and **semgrep** runs security-focused static analysis (the `p/auto` ruleset). Any finding blocks the commit. To skip the hooks for a commit (use sparingly): `git commit --no-verify`.

### Running tests

```
bundle exec rake test                          # full suite
bundle exec ruby -Itest test/services/search_test.rb   # just one file
bundle exec rubocop                            # style check (must stay clean)
```

The suite is integration/unit tests only — no browser/system tests (the polling JS glue is thin and untested, a deliberate tradeoff). No Chrome or driver gems are needed; CI runs `bundle exec rake test` directly.

## Running on Termux (Android)

If the repo is private, no GitHub login is needed on the phone — package the app source on your Mac and transfer it:

```
# on your Mac (inside the repo)
git archive --format=tar.gz -o einthusanlib.tar.gz HEAD

# transfer it however you like (scp requires Termux sshd once on the phone:
#   pkg install openssh && passwd && sshd   (sshd listens on port 8022)
# otherwise copy the tarball via USB / cloud)

# on the phone
tar xzf einthusanlib.tar.gz
cd einthusanlib
bash script/termux_setup.sh   # install deps, gems, and prepare the app (run once)
bash script/termux_start.sh   # start the server on your LAN at http://<phone-ip>:3000
```
