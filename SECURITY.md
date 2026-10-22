# Security and privacy

Codex Starwake uses a per-user LaunchAgent and AppKit application-launch notifications. It does not require root privileges, Accessibility access, Screen Recording access, a network listener, CDP, API keys or account credentials.

The animation runs as local HTML, CSS and JavaScript in WKWebView. Treat custom web assets as executable content: install themes only from sources you trust. The native bridge accepts lifecycle messages (`ready`, `finish`, `error`) and is intended only for this bundled page.

The installer refuses to replace an unmanaged destination or an unrelated LaunchAgent. Uninstall verifies the installation marker and moves only managed files to Trash. The marker prevents accidental removal; it is not a defense against a malicious process already running as your user.

Logs contain lifecycle events, process identifiers and errors. No telemetry is sent. Development tooling such as npm, git and Playwright can access the network separately from application runtime.

For a potential security issue, use the repository's private vulnerability reporting option if enabled. If unavailable, open an issue requesting a private contact without publishing exploit details or sensitive data. Please do not submit credentials, private conversation data or another user's files.
