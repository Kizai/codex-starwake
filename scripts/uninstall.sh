#!/bin/zsh
source "${0:A:h}/common.sh"
require_macos
require_managed
check_agent_owner
[[ "$INSTALL_DIR" != "$HOME" && "$INSTALL_DIR" != / && "$INSTALL_DIR" != "$AGENTS_DIR" && "$INSTALL_DIR" != "$TRASH_DIR" ]] || fail 'Unsafe uninstall target.'
service disable "$SERVICE_DOMAIN/$SERVICE_LABEL"
service bootout "$SERVICE_DOMAIN/$SERVICE_LABEL" 2>/dev/null || true
/bin/mkdir -p "$TRASH_DIR"
DESTINATION="$TRASH_DIR/Codex Starwake-$(/bin/date +%Y%m%d-%H%M%S)-$$"
[[ ! -e "$DESTINATION" ]] || fail 'Trash destination already exists.'
/bin/mkdir "$DESTINATION"
if [[ -f "$AGENT_PATH" ]]; then /bin/mv "$AGENT_PATH" "$DESTINATION/$SERVICE_LABEL.plist"; fi
/bin/mv "$INSTALL_DIR" "$DESTINATION/installation"
print -r -- "Uninstalled. Recoverable files moved to: $DESTINATION"
