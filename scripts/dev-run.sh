#!/usr/bin/env bash
# Build (if needed) and run cool-retro-term using the Nix-provided Qt toolchain.
#
# The resulting build/native/cool-retro-term.app is self-contained (via an
# embedded qt.conf) and can be double-clicked from Finder afterwards without
# re-running this script or setting any environment variables.
#
# Set CRT_DEFAULT_ARGS to bake default launch arguments into the icon, e.g.:
#   CRT_DEFAULT_ARGS="--fullscreen" ./scripts/dev-run.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
BUILD_DIR="$REPO_ROOT/build/native"
JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}"
DEFAULT_ARGS="${CRT_DEFAULT_ARGS:-}"

mkdir -p "$BUILD_DIR"

nix develop "$REPO_ROOT" --command bash -c '
set -euo pipefail
cd "'"$BUILD_DIR"'"
qmake CONFIG+=release "'"$REPO_ROOT"'/cool-retro-term.pro"
make -j'"$JOBS"'

# Qt keeps a persistent per-user QML bytecode cache keyed in a way that does
# not reliably invalidate across rebuilds of qrc-embedded QML (the app.pro
# organizationName/applicationName are both "cool-retro-term"). Without this,
# a rebuilt binary can silently keep running stale compiled QML.
rm -rf "$HOME/Library/Caches/cool-retro-term/cool-retro-term/qmlcache"

APP="cool-retro-term.app"
QT_PLUGINS="$(qmake -query QT_INSTALL_PLUGINS)"
QT_QML="$(qmake -query QT_INSTALL_QML)"
MERGED_QML="$PWD/$APP/Contents/PlugIns/qml"

rm -rf "$MERGED_QML"
mkdir -p "$MERGED_QML"
for d in "$QT_QML"/*; do
    ln -s "$d" "$MERGED_QML/$(basename "$d")"
done
rm -rf "$MERGED_QML/QMLTermWidget"
cp -R "$PWD/qmltermwidget/QMLTermWidget" "$MERGED_QML/QMLTermWidget"

mkdir -p "$APP/Contents/Resources"
cat > "$APP/Contents/Resources/qt.conf" <<EOF
[Paths]
Plugins = $QT_PLUGINS
Qml2Imports = PlugIns/qml
EOF

# Wrap the real binary so double-clicking the icon can bake in default
# launch arguments (e.g. always start --fullscreen). Only do this when the
# current executable is the freshly linked Mach-O binary, so reruns with
# nothing to rebuild do not wrap an already-installed wrapper.
BIN="$APP/Contents/MacOS/cool-retro-term"
BIN_REAL="$APP/Contents/MacOS/cool-retro-term-bin"
if file "$BIN" | grep -q "Mach-O"; then
    mv -f "$BIN" "$BIN_REAL"
fi
cat > "$BIN" <<WRAPEOF
#!/bin/bash
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
exec "\$DIR/cool-retro-term-bin" '"$DEFAULT_ARGS"' "\$@"
WRAPEOF
chmod +x "$BIN"

exec "$BIN" "$@"
' -- "$@"
