#!/bin/zsh
source "${0:A:h}/common.sh"
require_macos
require_managed
check_agent_owner
print -r -- "Installed: $INSTALL_DIR"
service print "$SERVICE_DOMAIN/$SERVICE_LABEL"
