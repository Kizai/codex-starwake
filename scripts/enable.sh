#!/bin/zsh
source "${0:A:h}/common.sh"
require_macos
require_managed
check_agent_owner
[[ -f "$AGENT_PATH" ]] || fail 'LaunchAgent missing; run the installer again.'
service enable "$SERVICE_DOMAIN/$SERVICE_LABEL"
service bootout "$SERVICE_DOMAIN/$SERVICE_LABEL" 2>/dev/null || true
service bootstrap "$SERVICE_DOMAIN" "$AGENT_PATH"
print 'Codex Starwake enabled.'
