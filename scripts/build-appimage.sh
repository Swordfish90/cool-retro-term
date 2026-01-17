#!/usr/bin/env bash
set -euo pipefail
set -x

REPO_ROOT="$(readlink -f "$(dirname "$(dirname "$0")")")"
OLD_CWD="$(readlink -f .)"
BUILD_DIR="$REPO_ROOT/build/appimage"
TOOLS_DIR="$BUILD_DIR/tools"

if ! command -v qmake >/dev/null; then
    echo "qmake not found in PATH." >&2
    exit 1
fi
QTDIR="$(qmake -query QT_INSTALL_PREFIX)"
QT_INSTALL_QML="$(qmake -query QT_INSTALL_QML)"

APPDIR="$BUILD_DIR/AppDir"

mkdir -p "$BUILD_DIR"
rm -rf "$APPDIR"
pushd "$BUILD_DIR"

qmake "$REPO_ROOT/cool-retro-term.pro"
make -j"$(nproc)"

# Install targets from subprojects (the top-level install only installs the desktop file).
make -C app install INSTALL_ROOT="$APPDIR"
make -C qmltermwidget install INSTALL_ROOT="$APPDIR"
make install INSTALL_ROOT="$APPDIR"

popd

# Relocate QMLTermWidget into the standard AppDir QML import path.
QML_ROOT="$APPDIR$QT_INSTALL_QML"
if [ -d "$QML_ROOT" ]; then
    mkdir -p "$APPDIR/usr/qml"
    rsync -a "$QML_ROOT/" "$APPDIR/usr/qml/"
    rm -rf "$QML_ROOT"
    QML_PARENT="$(dirname "$QML_ROOT")"
    while [ "$QML_PARENT" != "$APPDIR" ] && rmdir "$QML_PARENT" 2>/dev/null; do
        QML_PARENT="$(dirname "$QML_PARENT")"
    done
fi


# Build AppImage using linuxdeploy and linuxdeploy-plugin-qt.
mkdir -p "$TOOLS_DIR"
LINUXDEPLOY="$TOOLS_DIR/linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_QT="$TOOLS_DIR/linuxdeploy-plugin-qt-x86_64.AppImage"
if [ ! -x "$LINUXDEPLOY" ]; then
    wget -c -O "$LINUXDEPLOY" https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod +x "$LINUXDEPLOY"
fi
if [ ! -x "$LINUXDEPLOY_QT" ]; then
    wget -c -O "$LINUXDEPLOY_QT" https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
    chmod +x "$LINUXDEPLOY_QT"
fi

export QML_SOURCES_PATHS="$REPO_ROOT/app"

pushd "$BUILD_DIR"

export EXTRA_PLATFORM_PLUGINS="libqwayland.so;"
export EXTRA_QT_MODULES="sql;waylandcompositor;waylandclient"
export DEPLOY_PLATFORM_THEMES=true
export LINUXDEPLOY_EXCLUDED_LIBRARIES="libmysqlclient.so;libqsqlmimer.so;libqsqlmysql.so;libqsqlodbc.so;libqsqlpsql.so;libqsqloci.so;libqsqlibase.so"

"$LINUXDEPLOY" \
    --appdir "$APPDIR" \
    -e "$APPDIR/usr/bin/cool-retro-term" \
    -i "$REPO_ROOT/app/icons/256x256/cool-retro-term.png" \
    -d "$REPO_ROOT/cool-retro-term.desktop" \
    --plugin qt \
    --output appimage

mv ./*.AppImage "$OLD_CWD"
popd
