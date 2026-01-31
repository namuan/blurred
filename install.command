#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$SCRIPT_DIR/Blurred.xcodeproj"
SCHEME="Blurred"
CONFIGURATION="${1:-Release}"
DERIVED_DATA_PATH="$SCRIPT_DIR/build"

DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/Blurred.app"

build() {
	/usr/bin/xcodebuild \
		-project "$PROJECT" \
		-scheme "$SCHEME" \
		-configuration "$CONFIGURATION" \
		-derivedDataPath "$DERIVED_DATA_PATH" \
		build
}

build_without_codesign() {
	/usr/bin/xcodebuild \
		-project "$PROJECT" \
		-scheme "$SCHEME" \
		-configuration "$CONFIGURATION" \
		-derivedDataPath "$DERIVED_DATA_PATH" \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		build
}

echo "Building $SCHEME ($CONFIGURATION)..."

set +e
build
status=$?
set -e

if [ "$status" -ne 0 ]; then
	echo ""
	echo "Build failed. Retrying with code signing disabled (unsigned build)."
	echo "Note: the auto-start helper may not work without proper signing."
	echo ""
	build_without_codesign
fi

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/Blurred.app"
if [ ! -d "$APP_PATH" ]; then
	APP_PATH="$(/usr/bin/find "$DERIVED_DATA_PATH/Build/Products" -maxdepth 2 -name "Blurred.app" -print -quit)"
fi

if [ -z "${APP_PATH:-}" ] || [ ! -d "$APP_PATH" ]; then
	echo "Error: could not find Blurred.app under: $DERIVED_DATA_PATH/Build/Products"
	exit 1
fi

/bin/mkdir -p "$DEST_DIR"

if [ -d "$DEST_APP" ]; then
	backup="$DEST_DIR/Blurred.app.bak.$(/bin/date +%Y%m%d-%H%M%S)"
	echo "Backing up existing install to: $backup"
	/bin/mv "$DEST_APP" "$backup"
fi

echo "Installing to: $DEST_APP"
/usr/bin/ditto "$APP_PATH" "$DEST_APP"

echo "Done."
