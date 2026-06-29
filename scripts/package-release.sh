#!/bin/sh
set -eu

. "$(dirname "$0")/common.sh"

DIST_DIR="$ROOT_DIR/Dist"
STAGE_DIR="$DIST_DIR/SwiftCurlCffi-iOS"
ZIP_PATH="$DIST_DIR/SwiftCurlCffi-iOS.zip"

require_command zip

[ -f "$RESOURCES_DIR/curl_cffi_ios_payload.zip" ] || die "payload missing; run scripts/build-all.sh first"
[ -f "$RESOURCES_DIR/manifest.json" ] || die "manifest missing; run scripts/build-all.sh first"

rm -rf "$DIST_DIR"
mkdir -p "$STAGE_DIR"

rsync -au --delete \
  --exclude .git \
  --exclude .github \
  --exclude .build \
  --exclude .swiftpm \
  --exclude Artifacts \
  --exclude Build \
  --exclude Dist \
  "$ROOT_DIR/" "$STAGE_DIR/"

(
  cd "$DIST_DIR"
  zip -qry "$ZIP_PATH" "SwiftCurlCffi-iOS"
)

log "release zip written to $ZIP_PATH"
