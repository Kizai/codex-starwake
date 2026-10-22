#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${${(%):-%N}:A:h:h}"
SERVICE_LABEL="io.github.kizai.codex-starwake"
SERVICE_DOMAIN="gui/$(/usr/bin/id -u)"
INSTALL_DIR="${STARWAKE_INSTALL_DIR:-$HOME/Library/Application Support/Codex Starwake}"
AGENTS_DIR="${STARWAKE_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
AGENT_PATH="$AGENTS_DIR/$SERVICE_LABEL.plist"
TRASH_DIR="${STARWAKE_TRASH_DIR:-$HOME/.Trash}"
MANAGED_ID="io.github.kizai.codex-starwake/v1"

fail() { print -u2 -r -- "Starwake: $*"; exit 1; }
require_macos() {
  [[ "$(/usr/bin/uname -s)" == Darwin ]] || fail 'macOS 13 or later is required.'
  local macos_version
  macos_version="$(/usr/bin/sw_vers -productVersion)"
  (( ${macos_version%%.*} >= 13 )) || fail 'macOS 13 or later is required.'
  (( EUID != 0 )) || fail 'Run as your normal user, without sudo.'
}
is_managed() {
  [[ -d "$INSTALL_DIR" && ! -L "$INSTALL_DIR" && -f "$INSTALL_DIR/.starwake-managed" ]] &&
    [[ "$(<"$INSTALL_DIR/.starwake-managed")" == "$MANAGED_ID" ]]
}
require_managed() { is_managed || fail "No managed installation at: $INSTALL_DIR"; }
check_agent_owner() {
  [[ ! -L "$AGENT_PATH" ]] || fail "Refusing to replace a symlink: $AGENT_PATH"
  if [[ -e "$AGENT_PATH" ]]; then
    local existing_label existing_binary
    existing_label=$(/usr/bin/plutil -extract Label raw -o - "$AGENT_PATH")
    existing_binary=$(/usr/bin/plutil -extract ProgramArguments.0 raw -o - "$AGENT_PATH")
    [[ "$existing_label" == "$SERVICE_LABEL" && "$existing_binary" == "$INSTALL_DIR/Starwake" ]] ||
      fail "Refusing to change an unrelated LaunchAgent: $AGENT_PATH"
  fi
}
service() {
  if [[ "${STARWAKE_SKIP_LAUNCHCTL:-0}" == 1 ]]; then
    print -r -- "[test mode: launchctl skipped] $*"
  else
    /bin/launchctl "$@"
  fi
}
