# Installation / 安装说明

## Requirements / 系统要求

- macOS 13 or newer, Apple Silicon or Intel.
- Apple Command Line Tools (`xcode-select --install`).
- Codex desktop, bundle identifier `com.openai.codex`. Installation itself can complete before Codex is installed; the watcher remains idle until the matching app starts.
- A normal signed-in desktop user. Do not use `sudo`, SSH-only sessions or a system-wide LaunchDaemon.

Node.js and Playwright are development-only dependencies. The installed helper uses Apple system frameworks and local assets.

## Install / 安装

```sh
git clone https://github.com/Kizai/codex-starwake.git
cd codex-starwake
zsh scripts/install.sh
```

The installer builds a binary for the current architecture, copies the animation and management scripts into `~/Library/Application Support/Codex Starwake/`, generates an escaped per-user plist, and loads it into `launchctl gui/<uid>`. `RunAtLoad` and `KeepAlive` apply to the helper, not to Codex. Quitting Codex will not relaunch Codex.

安装后请完全退出 Codex 再打开。普通的窗口切换和点击已在运行的应用不会重播。安装操作不会退出当前会话。助手自身退出时由 launchd 恢复；Codex 仍然由你正常开启或退出。

The source ZIP also contains **Install.command**. If Finder cannot execute a downloaded script, use `zsh scripts/install.sh` from Terminal after reviewing the source. Do not disable Gatekeeper globally.

## Manage / 管理

From the checkout:

```sh
zsh scripts/status.sh
zsh scripts/disable.sh
zsh scripts/enable.sh
zsh scripts/uninstall.sh
```

Without the checkout:

```sh
zsh "$HOME/Library/Application Support/Codex Starwake/scripts/disable.sh"
zsh "$HOME/Library/Application Support/Codex Starwake/scripts/enable.sh"
zsh "$HOME/Library/Application Support/Codex Starwake/scripts/uninstall.sh"
```

Disable retains the animation and plist but unloads the helper and disables its automatic loading. Enable reverses that. Uninstall additionally moves the managed installation and plist into a timestamped directory in Trash. Reinstalling from source restores the feature. If restoring files manually from Trash, put both the installation and the plist back in their original locations, then run `enable.sh`.

Custom files inside the managed installation also move to Trash during uninstall. Reinstall overwrites the shipped web files, so keep your custom image in the source checkout or back it up first.

## Troubleshooting / 常见问题

### Nothing happens / 没有动画

1. Fully quit Codex, then launch it again. A focus change is not a new app launch.
2. Run `zsh scripts/status.sh` and look for `state = running`.
3. Check `~/Library/Application Support/Codex Starwake/watcher.log` for `[starwake] watcher-ready` and `launch-detected`.
4. Check the neighboring `watcher-error.log` for errors.
5. Ensure the background helper remains enabled in macOS login/background item settings.

For an app at a custom location, the automatic watcher still identifies it by `com.openai.codex`. To use the manual launcher:

```sh
zsh scripts/launch.sh --codex-app "/path/to/Codex.app"
```

### Compiler missing / 没有 Swift 编译器

Run `xcode-select --install`, finish the Apple installer, then rerun the Starwake installer. `open web/index.html` provides a browser preview without compiling anything.

### `Bootstrap failed` / 服务加载失败

Run installation from a normal desktop Terminal without `sudo`. Run `zsh scripts/disable.sh`, then `zsh scripts/enable.sh`. If the LaunchAgent is missing, reinstall. Include the exact error when opening an issue; redact personal paths if desired.

### macOS displays ChatGPT instead of Codex

Some Codex builds use the ChatGPT display name. The project matches the application bundle identifier, not the name or icon. You can inspect it with:

```sh
plutil -extract CFBundleIdentifier raw -o - "/Applications/Codex.app/Contents/Info.plist"
# Or inspect the relevant .app at its actual installation path.
```

### Already using the earlier local prototype / 已安装早期本机原型

The prototype used a different service label (`local.codex.shorekeeper-startup`) and directory (`Codex Shorekeeper`). Run that prototype's **关闭自动启动动画.command** before enabling this open-source version, to avoid two helpers playing the same animation. The installer deliberately leaves that separate installation untouched.

### Privacy / 隐私

The helper observes local application launch notifications and matches the target bundle identifier. It does not read Codex conversations, API keys, model configuration or browser data. Runtime assets are local and have no HTTP requests. Logs record lifecycle events, process identifiers and errors; paths may appear in error messages. Installing Command Line Tools or cloning the repository can use the network separately.
