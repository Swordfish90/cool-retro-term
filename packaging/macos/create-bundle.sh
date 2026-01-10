#!/bin/bash
#
# create-bundle.sh - Create a standalone macOS app bundle for cool-retro-term
#
# This script creates a fully self-contained .app bundle that includes all
# Qt frameworks and plugins, suitable for distribution without requiring
# Qt to be installed on the target system.
#
# Requirements:
#   - Qt5 installed via Homebrew: brew install qt@5
#   - Xcode Command Line Tools: xcode-select --install
#
# Usage:
#   ./packaging/macos/create-bundle.sh
#
# Output:
#   ./cool-retro-term.app (standalone bundle)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUNDLE="$PROJECT_ROOT/cool-retro-term.app"

# Find Qt5
if [ -d "/opt/homebrew/opt/qt@5" ]; then
    QT_PATH="/opt/homebrew/opt/qt@5"
elif [ -d "/usr/local/opt/qt@5" ]; then
    QT_PATH="/usr/local/opt/qt@5"
else
    echo "Error: Qt5 not found. Install with: brew install qt@5"
    exit 1
fi

QMAKE="$QT_PATH/bin/qmake"
MACDEPLOYQT="$QT_PATH/bin/macdeployqt"

echo "Using Qt5 from: $QT_PATH"
echo "Project root: $PROJECT_ROOT"

cd "$PROJECT_ROOT"

# Ensure submodules are initialized
echo "==> Initializing submodules..."
git submodule update --init

# Clean previous build
echo "==> Cleaning previous build..."
if [ -f Makefile ]; then
    make clean 2>/dev/null || true
fi
rm -rf "$BUNDLE"

# Build
echo "==> Running qmake..."
"$QMAKE" CONFIG+=release

echo "==> Building..."
make -j$(sysctl -n hw.ncpu)

# Verify build succeeded
if [ ! -d "$BUNDLE" ]; then
    echo "Error: Build failed - app bundle not created"
    exit 1
fi

# Deploy Qt frameworks
echo "==> Deploying Qt frameworks..."
"$MACDEPLOYQT" "$BUNDLE" \
    -qmldir="$PROJECT_ROOT/app/qml" \
    -qmldir="$PROJECT_ROOT/qmltermwidget" \
    -always-overwrite

# Copy QMLTermWidget plugin
echo "==> Adding QMLTermWidget plugin..."
cp -R "$PROJECT_ROOT/qmltermwidget/QMLTermWidget" "$BUNDLE/Contents/Resources/qml/"

# Fix library paths
echo "==> Fixing library paths..."

QT_FRAMEWORKS="QtQuick QtWidgets QtGui QtQmlModels QtQml QtNetwork QtCore QtSql QtQuickControls2 QtSvg QtVirtualKeyboard QtQuickTemplates2 QtDBus QtPrintSupport QtConcurrent"

fix_dylib() {
    local dylib="$1"
    local rel_path="${dylib#$BUNDLE/Contents/}"

    # Set the library ID
    install_name_tool -id "@executable_path/../$rel_path" "$dylib" 2>/dev/null || true

    # Fix Qt framework references (both symlink and direct paths)
    for fw in $QT_FRAMEWORKS; do
        install_name_tool -change "$QT_PATH/lib/${fw}.framework/Versions/5/${fw}" \
            "@executable_path/../Frameworks/${fw}.framework/Versions/5/${fw}" "$dylib" 2>/dev/null || true
        install_name_tool -change "/opt/homebrew/opt/qt@5/lib/${fw}.framework/Versions/5/${fw}" \
            "@executable_path/../Frameworks/${fw}.framework/Versions/5/${fw}" "$dylib" 2>/dev/null || true
        install_name_tool -change "/opt/homebrew/Cellar/qt@5/*/lib/${fw}.framework/Versions/5/${fw}" \
            "@executable_path/../Frameworks/${fw}.framework/Versions/5/${fw}" "$dylib" 2>/dev/null || true
    done
}

# Fix all dylibs in PlugIns
find "$BUNDLE/Contents/PlugIns" -name "*.dylib" -type f | while read dylib; do
    fix_dylib "$dylib"
done

# Fix Qt framework binaries
find "$BUNDLE/Contents/Frameworks" -name "Qt*" -path "*framework/Versions/5/*" -type f ! -name "*.prl" ! -name "*.plist" | while read fw; do
    fix_dylib "$fw"
done

# Fix all dylibs in Frameworks
find "$BUNDLE/Contents/Frameworks" -name "*.dylib" -type f | while read dylib; do
    fix_dylib "$dylib"
done

# Fix all dylibs in Resources/qml (non-symlinks)
find "$BUNDLE/Contents/Resources/qml" -name "*.dylib" -type f ! -type l | while read dylib; do
    fix_dylib "$dylib"
done

# Verify no Homebrew references remain
echo "==> Verifying library paths..."
HOMEBREW_REFS=$(find "$BUNDLE" -type f \( -name "*.dylib" -o -name "Qt*" \) -exec otool -L {} \; 2>/dev/null | grep -c "/opt/homebrew" || true)
if [ "$HOMEBREW_REFS" -gt 0 ]; then
    echo "Warning: $HOMEBREW_REFS Homebrew references still found"
    find "$BUNDLE" -type f \( -name "*.dylib" -o -name "Qt*" \) -exec sh -c 'otool -L "$1" 2>/dev/null | grep -q "/opt/homebrew" && echo "$1"' _ {} \;
fi

# Code sign
echo "==> Code signing..."
codesign --force --deep --sign - "$BUNDLE"

# Report results
BUNDLE_SIZE=$(du -sh "$BUNDLE" | cut -f1)
ARCH=$(file "$BUNDLE/Contents/MacOS/cool-retro-term" | grep -o 'arm64\|x86_64')

echo ""
echo "==> Bundle created successfully!"
echo "    Location: $BUNDLE"
echo "    Size: $BUNDLE_SIZE"
echo "    Architecture: $ARCH"
echo ""
echo "To install, copy to /Applications:"
echo "    cp -R '$BUNDLE' /Applications/"
