#!/bin/zsh
source "${0:A:h}/common.sh"
require_macos
/usr/bin/xcrun --find swiftc >/dev/null 2>&1 || fail 'Install Apple Command Line Tools first: xcode-select --install'
BUILD_DIR="$PROJECT_ROOT/.build"
BINARY="$BUILD_DIR/Starwake-$(/usr/bin/uname -m)"
/bin/mkdir -p "$BUILD_DIR"
if [[ ! -x "$BINARY" || "$PROJECT_ROOT/native/Starwake.swift" -nt "$BINARY" ]]; then
  print -u2 'Building Codex Starwake…'
  /usr/bin/xcrun swiftc "$PROJECT_ROOT/native/Starwake.swift" -O \
    -target "$(/usr/bin/uname -m)-apple-macosx13.0" \
    -framework AppKit -framework WebKit -module-cache-path "$BUILD_DIR/module-cache" -o "$BINARY"
fi
print -r -- "$BINARY"
