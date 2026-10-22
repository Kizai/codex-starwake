#!/bin/zsh
source "${0:A:h}/common.sh"
require_macos
for script in "$PROJECT_ROOT/scripts/"*.sh "$PROJECT_ROOT/"*.command; do /bin/zsh -n "$script"; done
node --check "$PROJECT_ROOT/web/animation.js"
"$PROJECT_ROOT/scripts/build.sh"
node --test "$PROJECT_ROOT/tests/install.test.mjs"
