# Contributing

Thank you for helping make Codex Starwake easier to install and enjoy.

## Development

Use macOS 13+ with Apple Command Line Tools. Node.js 20+ is needed for tests; the shipped application has no Node runtime dependency.

```sh
zsh scripts/check.sh
npm ci
npm run format:check
npx playwright install chromium
npm run test:browser
```

To use an existing local Chrome for browser tests, set `CHROME_PATH` to its executable. The optional `PLAYWRIGHT_MODULE` override accepts an existing Playwright package path. Both overrides are developer conveniences and are not used by the installed application.

`scripts/check.sh` compiles the Swift executable, checks shell and JavaScript syntax, and runs isolated installer tests. Those tests use temporary installation, LaunchAgents and Trash directories with `STARWAKE_SKIP_LAUNCHCTL=1`; they must never modify a developer's real login services. Custom path overrides are test hooks; normal users should use the default paths.

Preview with `zsh scripts/preview.sh`. To exercise the watcher event handler without quitting a running Codex:

```sh
BINARY="$(zsh scripts/build.sh)"
"$BINARY" "$PWD/web" --watch --test-open
```

This posts a synthetic launch notification inside the test process. It tests the event-to-animation path, not delivery of a real OS launch event. For manual acceptance, install, fully quit and reopen Codex twice, verify one animation per launch, skip one playback, disable and verify no playback, enable again, and test uninstall. Use a separate account or ensure your current work is saved before quitting Codex.

## Pull requests

- Describe the user-visible behavior and the checks actually run.
- Keep macOS lifecycle changes separate from unrelated visual changes when practical.
- Preserve cold-start-only behavior; ordinary focus changes must not trigger another splash.
- Do not modify official app bundles, add remote debugging ports, request account secrets or introduce runtime network dependencies.
- Do not commit `.build`, logs, local screenshots from private work, personal paths or generated test reports.
- For artwork, provide source/provenance and permission information. Update `NOTICE.md` when adding assets.

## Visual changes

Keep typography readable over the illustration, preserve Skip/Escape/replay, and check a 1280×720 desktop viewport plus a narrow 390×844 viewport. Keep reduced-motion support. Export frames by opening `web/index.html?manual=1&film=1` and calling `window.shorekeeper.seek(milliseconds)`; total duration is 6800 milliseconds.

## Reporting issues

Include macOS version, Apple Silicon or Intel, the app bundle identifier and the exact error. Logs are under `~/Library/Application Support/Codex Starwake/`; redact personal paths before sharing. Do not include tokens, account details or conversation content.
