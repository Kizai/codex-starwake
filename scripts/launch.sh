#!/bin/zsh
source "${0:A:h}/common.sh"
BINARY="$("$PROJECT_ROOT/scripts/build.sh")"
exec "$BINARY" "$PROJECT_ROOT/web" "$@"
