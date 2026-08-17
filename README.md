A minimal Ruby web app built with Sinatra. Paste a URL, and it downloads the media in a background thread with live progress, then streams the finished file in the browser. No database, no background scheduler, no scraping — the only state is files on disk.

## How it works

- **One page** (`/`): a URL paste box, the current download status, and a library of downloaded files.
- **`POST /downloads`** — trims the library down to the 3 newest files and starts the download in a background thread. Only one download runs at a time; new pastes while busy are rejected with a notice.
- **`GET /status.json`** — polled by a tiny script every 10s for live progress (percent / speed / ETA, parsed from the downloader's output).
- **`GET /watch/:name`** — streams a finished file (range-aware, so seeking works).
- **No persistent state.** A crashed or interrupted download leaves only partial files in `tmp/downloads`, which are cleaned on boot and before each download. Restarting the server abandons any in-flight download and everything self-heals.
- **Storage hygiene**: before each download the app deletes all but the 3 most recently downloaded files; oversized downloads simply fail with a visible error message.

## Development

The project uses [mise](https://mise.jdx.dev) to manage the Ruby toolchain and a Python virtualenv (for the downloader).

```
mise install        # installs ruby 3.2.3, python, and the dev tools
mise run setup      # creates venv, installs the downloader, gems, pre-commit hooks
bundle exec puma    # starts the server on http://localhost:9292
```

The downloader uses [aria2c](https://aria2.github.io) (multi-connection) when available — many CDNs throttle single connections to ~10-25 KiB/s, but 16 parallel connections sustain ~2 MB/s. On macOS install it with `brew install aria2`; on Termux it's included in `script/termux_setup.sh`. Without aria2c the app falls back to a plain single-connection download.

### Running tests

```
bundle exec rake test          # full suite (small, happy-path only)
bundle exec rubocop            # style check (must stay clean)
```

## Running on Termux (Android)

Clone the repo on the phone, then set it up:

```
git clone <repo-url>
cd <repo-dir>
bash script/termux_setup.sh   # install deps, gems, and prepare the app (run once)
bash script/termux_start.sh   # start the server on your LAN at http://<phone-ip>:3000
```

To update later, `git pull` inside the repo and re-run `bash script/termux_setup.sh`.

Downloads run while the server is up, so keep the phone on Wi-Fi with the app awake (termux_start.sh acquires a wake lock). A download interrupted by a crash or reboot is detected and cleaned automatically.

## Disclaimer

This application is for educational and personal use only. Users are responsible for complying with applicable laws and the terms of service of content providers. The authors are not responsible for any misuse of this software.