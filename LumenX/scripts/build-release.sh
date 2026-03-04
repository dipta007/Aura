#!/bin/bash
set -e

APP_NAME="LumenX"
APP_DIR="$APP_NAME.app"
BUILD_DIR="dist"
DMG_NAME="$APP_NAME.dmg"

echo "Building $APP_NAME..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$APP_DIR/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_DIR/Contents/Resources"

# Copy binary
cp .build/release/$APP_NAME "$BUILD_DIR/$APP_DIR/Contents/MacOS/"

# Copy Info.plist
cp "$APP_NAME.app/Contents/Info.plist" "$BUILD_DIR/$APP_DIR/Contents/" 2>/dev/null || \
cp /Applications/$APP_DIR/Contents/Info.plist "$BUILD_DIR/$APP_DIR/Contents/"

# Bundle m1ddc (check bundled, homebrew, or local)
M1DDC_PATH=""
for path in /opt/homebrew/bin/m1ddc /usr/local/bin/m1ddc; do
    if [ -f "$path" ]; then
        M1DDC_PATH="$path"
        break
    fi
done

if [ -n "$M1DDC_PATH" ]; then
    cp "$M1DDC_PATH" "$BUILD_DIR/$APP_DIR/Contents/Resources/m1ddc"
    chmod +x "$BUILD_DIR/$APP_DIR/Contents/Resources/m1ddc"
    echo "Bundled m1ddc from $M1DDC_PATH"

    # Copy license
    M1DDC_PREFIX=$(brew --prefix m1ddc 2>/dev/null || true)
    if [ -f "$M1DDC_PREFIX/LICENSE" ]; then
        cp "$M1DDC_PREFIX/LICENSE" "$BUILD_DIR/$APP_DIR/Contents/Resources/m1ddc-LICENSE"
    fi
else
    echo "WARNING: m1ddc not found. External monitor control won't work without it."
    echo "Install with: brew install m1ddc"
fi

# Ad-hoc codesign
codesign --force --deep --sign - "$BUILD_DIR/$APP_DIR"
echo "Signed $APP_DIR"

# Create DMG
echo "Creating DMG..."
rm -f "$BUILD_DIR/$DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder "$BUILD_DIR/$APP_DIR" -ov -format UDZO "$BUILD_DIR/$DMG_NAME"

echo ""
echo "Done! Output:"
echo "  App: $BUILD_DIR/$APP_DIR"
echo "  DMG: $BUILD_DIR/$DMG_NAME"
