# Development

Run the app inside the provided devcontainer so gems and tools are already set up.

```
docker compose up -d
docker compose exec app bash
bin/rails server
```

## Running tests

```
bin/rails test           # full suite
bin/rails test test/services  # just services
bin/rubocop              # style check (must stay clean)
```

The suite is integration/unit tests only — no browser/system tests (the stimulus/Turbo glue is thin and untested, a deliberate tradeoff). No Chrome or driver gems are needed; CI runs `bin/rails test` directly.

## Testing conventions

No test hits the real network, and none needs a real youtube-dl binary. Three rules keep it that way:

1. **Scrapers use canned HTML.** `test/test_helper.rb` builds a minimal results page via `einthusan_list_html(...)`, and tests stub the network boundary with `URI.stub(:open, ...)`. Add sample data by passing hashes — never real HTML dumps.
2. **Downstream stubs `system` and pre-creates its temp file.** With the file present at `download_path`, the real `download` short-circuits (so youtube-dl is never invoked) while `attach`, `cleanup`, and the lock lifecycle all run for real. All tests assert the lock keys are released, since `ensure` is the contract to protect.
3. **The cache resets before every test.** Multiple features share cache keys (`recent_movies`, `downstreaming_<id>`, the global download lock), so each test starts from an empty `MemoryStore` via the shared `setup` in `test_helper.rb`.

`attach_video(movie)` attaches a small in-memory blob — use it whenever a test needs an attached video without a file on disk.

### Why these decisions

- **Stub at `URI.open`, not at the service method.** The interesting code is the parsing and `find_or_create_by` logic; stubbing at the network layer exercises it.
- **No WebMock/VCR.** The scrapers read one static HTML shape; a helper + stub is simpler than adding test-only gems to a deliberately slim `Gemfile`.
- **`Recent` and `Search` both tolerate network failure** (return `nil` + log). The views already handle `nil` — that is why search failure degrades to "no movies found" instead of a 500.