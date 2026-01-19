#!/usr/bin/env bash
set -euo pipefail
set -x

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
OLD_CWD="$(pwd -P)"
BUILD_DIR="$REPO_ROOT/build/dmg"
APP="cool-retro-term.app"
QML_DIR="$REPO_ROOT/app/qml"
JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}"
VERSION="$(git -C "$REPO_ROOT" describe --tags --always --dirty=-dirty 2>/dev/null || true)"
if [ -z "$VERSION" ]; then
    VERSION="unknown"
fi

if ! command -v qmake >/dev/null; then
    echo "qmake not found in PATH." >&2
    exit 1
fi
QT_DIR="${QT_DIR:-$(qmake -query QT_INSTALL_PREFIX)}"
QT_BIN="${QT_DIR%/}/bin"

mkdir -p "$BUILD_DIR"
rm -f "$BUILD_DIR/${APP%.app}.dmg"
pushd "$BUILD_DIR"

"$QT_BIN/qmake" CONFIG+=release "$REPO_ROOT/cool-retro-term.pro"
make -j"$JOBS"

PLUGIN_DST="$APP/Contents/PlugIns/qmltermwidget"
rm -rf "$PLUGIN_DST"
mkdir -p "$APP/Contents/PlugIns"
cp -R qmltermwidget/QMLTermWidget "$PLUGIN_DST"

export QML_IMPORT_PATH="$PWD/$APP/Contents/PlugIns"
"$QT_BIN/macdeployqt" "$APP" -qmldir="$QML_DIR" -dmg

rm -f "$APP/Contents/PlugIns/sqldrivers/"libqsql{odbc,psql,mimer}.dylib 2>/dev/null || true
DMG_OUT="${APP%.app}-${VERSION}.dmg"
mv "$BUILD_DIR/${APP%.app}.dmg" "$OLD_CWD/$DMG_OUT"
popd
