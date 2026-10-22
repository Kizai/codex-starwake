#!/bin/zsh
source "${0:A:h}/common.sh"
require_macos
[[ "$INSTALL_DIR" == /* && "$AGENTS_DIR" == /* ]] || fail 'Installation paths must be absolute.'
[[ ! -L "$INSTALL_DIR" ]] || fail 'Refusing to install into a symlink.'
if [[ -e "$INSTALL_DIR" ]] && ! is_managed; then
  fail "The destination exists and was not created by Starwake: $INSTALL_DIR"
fi
check_agent_owner
BINARY="$("$PROJECT_ROOT/scripts/build.sh")"
# Validate every source before stopping a previous installation.
for item in web/index.html web/style.css web/animation.js web/assets/shorekeeper.png support/managed-marker; do
  [[ -f "$PROJECT_ROOT/$item" ]] || fail "Missing distribution file: $item"
done
if [[ -f "$AGENT_PATH" ]]; then service bootout "$SERVICE_DOMAIN/$SERVICE_LABEL" 2>/dev/null || true; fi
/bin/mkdir -p "$INSTALL_DIR/web/assets" "$INSTALL_DIR/scripts" "$AGENTS_DIR"
/bin/cp "$BINARY" "$INSTALL_DIR/Starwake.next"
/bin/chmod 755 "$INSTALL_DIR/Starwake.next"
/bin/mv -f "$INSTALL_DIR/Starwake.next" "$INSTALL_DIR/Starwake"
/bin/cp "$PROJECT_ROOT/support/managed-marker" "$INSTALL_DIR/.starwake-managed"
for item in index.html style.css animation.js; do /bin/cp "$PROJECT_ROOT/web/$item" "$INSTALL_DIR/web/$item"; done
/bin/cp "$PROJECT_ROOT/web/assets/shorekeeper.png" "$INSTALL_DIR/web/assets/shorekeeper.png"
for item in common.sh enable.sh disable.sh status.sh uninstall.sh; do
  /bin/cp "$PROJECT_ROOT/scripts/$item" "$INSTALL_DIR/scripts/$item"
done
for item in Enable.command Disable.command Uninstall.command; do /bin/cp "$PROJECT_ROOT/$item" "$INSTALL_DIR/$item"; done
/bin/chmod 755 "$INSTALL_DIR/scripts/"*.sh "$INSTALL_DIR/"*.command
# plutil escapes spaces, ampersands and other XML metacharacters in user paths.
PLIST="$INSTALL_DIR/agent.next.plist"
/usr/bin/plutil -create xml1 "$PLIST"
/usr/bin/plutil -insert Label -string "$SERVICE_LABEL" "$PLIST"
/usr/bin/plutil -insert ProgramArguments -array "$PLIST"
/usr/bin/plutil -insert ProgramArguments.0 -string "$INSTALL_DIR/Starwake" "$PLIST"
/usr/bin/plutil -insert ProgramArguments.1 -string "$INSTALL_DIR/web" "$PLIST"
/usr/bin/plutil -insert ProgramArguments.2 -string '--watch' "$PLIST"
/usr/bin/plutil -insert RunAtLoad -bool true "$PLIST"
/usr/bin/plutil -insert KeepAlive -bool true "$PLIST"
/usr/bin/plutil -insert ThrottleInterval -integer 10 "$PLIST"
/usr/bin/plutil -insert ProcessType -string Interactive "$PLIST"
/usr/bin/plutil -insert LimitLoadToSessionType -string Aqua "$PLIST"
/usr/bin/plutil -insert StandardOutPath -string "$INSTALL_DIR/watcher.log" "$PLIST"
/usr/bin/plutil -insert StandardErrorPath -string "$INSTALL_DIR/watcher-error.log" "$PLIST"
/usr/bin/plutil -lint "$PLIST"
/bin/mv -f "$PLIST" "$AGENT_PATH"
/bin/chmod 644 "$AGENT_PATH"
service enable "$SERVICE_DOMAIN/$SERVICE_LABEL"
service bootstrap "$SERVICE_DOMAIN" "$AGENT_PATH"
print -r -- "Installed: $INSTALL_DIR"
print 'Starwake will play when Codex next starts. Switching windows does not replay it.'
print 'If macOS shows a background-item notification, keep Codex Starwake enabled.'
