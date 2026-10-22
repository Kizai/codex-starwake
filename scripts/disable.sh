#!/bin/zsh
source "${0:A:h}/common.sh"
require_macos
require_managed
check_agent_owner
service disable "$SERVICE_DOMAIN/$SERVICE_LABEL"
service bootout "$SERVICE_DOMAIN/$SERVICE_LABEL" 2>/dev/null || true
print 'Codex Starwake disabled. Your animation files are retained.'
