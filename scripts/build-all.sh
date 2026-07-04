#!/bin/sh
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

. "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

if [ "$SWIFTCURL_CLEAN_BUILD" = "1" ]; then
  "$SCRIPT_DIR/clean.sh"
fi

"$SCRIPT_DIR/fetch-sources.sh"
"$SCRIPT_DIR/build-libffi.sh"
"$SCRIPT_DIR/build-curl-impersonate.sh"
"$SCRIPT_DIR/build-python-payload.sh"
