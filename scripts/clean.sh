#!/bin/sh
set -eu

. "$(dirname "$0")/common.sh"

parse_common_args "$@"

rm -rf "$BUILD_DIR" "$ARTIFACTS_DIR"
rm -f "$RESOURCES_DIR/curl_cffi_ios_payload.zip"
rm -f "$RESOURCES_DIR/manifest.json"
rm -f "$RESOURCES_DIR/.artifact-ready"

log "removed generated build outputs"
