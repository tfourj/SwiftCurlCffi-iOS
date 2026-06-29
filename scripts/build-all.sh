#!/bin/sh
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

"$SCRIPT_DIR/fetch-sources.sh"
"$SCRIPT_DIR/build-libffi.sh"
"$SCRIPT_DIR/build-curl-impersonate.sh"
"$SCRIPT_DIR/build-python-payload.sh"

