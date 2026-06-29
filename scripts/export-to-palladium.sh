#!/bin/sh
set -eu

. "$(dirname "$0")/common.sh"

PALLADIUM_ROOT="${PALLADIUM_ROOT:-$ROOT_DIR/../Palladium}"
DEST="$PALLADIUM_ROOT/Frameworks/SwiftCurlCffi-iOS"

[ -f "$RESOURCES_DIR/curl_cffi_ios_payload.zip" ] || die "payload missing; run scripts/build-all.sh first"
[ -d "$PALLADIUM_ROOT" ] || die "Palladium root not found: $PALLADIUM_ROOT"

mkdir -p "$DEST"
rsync -au --delete \
  --exclude .git \
  --exclude .build \
  --exclude .swiftpm \
  --exclude Build \
  --exclude Artifacts \
  "$ROOT_DIR/" "$DEST/"

log "exported Swift package to $DEST"

