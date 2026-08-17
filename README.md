# Einthusanlib

A lightweight Ruby web app that downloads and streams movies from Einthusan. Built on Sinatra — no database, no background scheduler, no scraping.

Paste an Einthusan movie URL, and the app downloads it with youtube-dl (+ aria2c for parallel connections). The page shows live progress while it downloads; once finished, the movie appears in the library and streams in the browser.

## How it works

- **One page** (`/`): a URL paste box, the current download status, and a library of downloaded movies.
- **`POST /downloads`** — validates that the URL is from `einthusan.tv`, trims the library down to the 3 newest movies, and starts the download in a background thread. Only one download runs at a time; new pastes while busy are rejected with a notice.
- **`GET /status.json`** — polled by a tiny script every 30s for live progress (percent / speed / ETA, parsed from the downloader's output).
- **`GET /watch/:name`** — streams a finished movie (range-aware, so seeking works).
- **No persistent state.** The library is just the files in `storage/movies`. A crashed or interrupted download leaves only partial files in `tmp/downloads`, which are cleaned on boot and before each download. Restarting the server abandons any in-flight download and everything self-heals.
- **Storage hygiene**: before each download the app deletes all but the 3 most recently downloaded movies; oversized downloads simply fail with a visible error message.

## Development

The project uses [mise](https://mise.jdx.dev) to manage the Ruby toolchain and a Python virtualenv (for youtube-dl).

```
mise install        # installs ruby 3.2.3, python, and the dev tools
mise run setup      # creates venv, installs youtube-dl, gems, pre-commit hooks
bundle exec puma    # starts the server on http://localhost:9292
```

The downloader uses [aria2c](https://aria2.github.io) (multi-connection) when available — the Einthusan CDN throttles single connections to ~10-25 KiB/s, but 16 parallel connections sustain ~2 MB/s. On macOS install it with `brew install aria2`; on Termux it's included in `script/termux_setup.sh`. Without aria2c the app falls back to a plain youtube-dl download.

### Running tests

```
bundle exec rake test          # full suite (small, happy-path only)
bundle exec rubocop            # style check (must stay clean)
```

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

Downloads run while the server is up, so keep the phone on Wi-Fi with the app awake (termux_start.sh acquires a wake lock). A download interrupted by a crash or reboot is detected and cleaned automatically.

### Accessing from a computer

The server is reachable two ways at once: `localhost:3000` on the phone itself, and `http://<phone-ip>:3000` from any device on the same Wi-Fi. Open the printed `LAN address` (e.g. `http://192.168.1.50:3000`) in a browser on your computer.

To check connectivity from the computer:

    ping <phone-ip>
    curl -sI http://<phone-ip>:3000

If that doesn't load:
- make sure the phone is on Wi-Fi, not mobile data;
- confirm the printed address is a private IP (`192.168.x.x` / `10.x.x.x`), not `127.0.0.1`;
- disable "AP/client isolation" (or a guest network) on your router, which blocks device-to-device traffic.

The server can't be reached from the internet on mobile data (carriers use CG-NAT, which blocks inbound connections). If you ever need remote access, use a tunnel such as Tailscale.

## ⚠️ Disclaimer

This application is for educational and personal use only. Users are responsible for complying with applicable laws and the terms of service of content providers. The authors are not responsible for any misuse of this software.