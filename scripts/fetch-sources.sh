#!/bin/sh
set -eu

. "$(dirname "$0")/common.sh"

ensure_tools
prepare_dirs

download_and_extract() {
  name=$1
  url=$2
  target=$3
  archive="$SOURCES_DIR/$name.tar.gz"

  if [ -d "$target" ]; then
    log "$name already fetched"
    return
  fi

  log "downloading $name"
  curl -fL "$url" -o "$archive"
  mkdir -p "$target.tmp"
  tar -xzf "$archive" -C "$target.tmp" --strip-components 1
  mv "$target.tmp" "$target"
}

download_pypi_sdist() {
  project=$1
  version=$2
  target=$3
  download_dir="$SOURCES_DIR/pypi"

  if [ -d "$target" ]; then
    log "$project already fetched"
    return
  fi

  log "downloading $project==$version"
  mkdir -p "$download_dir" "$target.tmp"
  "$HOST_PYTHON" -m pip download \
    --no-binary :all: \
    --no-deps \
    --dest "$download_dir" \
    "$project==$version"

  archive=$(find "$download_dir" -maxdepth 1 -name "*.tar.gz" -print | grep "/$project-" | head -1 || true)
  if [ -z "$archive" ] && [ "$project" = "curl-cffi" ]; then
    archive=$(find "$download_dir" -maxdepth 1 -name "curl_cffi-*.tar.gz" -print | head -1 || true)
  fi
  [ -n "$archive" ] || die "downloaded sdist not found for $project"

  tar -xzf "$archive" -C "$target.tmp" --strip-components 1
  mv "$target.tmp" "$target"
}

download_and_extract \
  "libffi-$LIBFFI_VERSION" \
  "https://github.com/libffi/libffi/releases/download/v$LIBFFI_VERSION/libffi-$LIBFFI_VERSION.tar.gz" \
  "$SOURCES_DIR/libffi"

download_pypi_sdist "cffi" "$CFFI_VERSION" "$SOURCES_DIR/cffi"
download_pypi_sdist "curl-cffi" "$CURL_CFFI_VERSION" "$SOURCES_DIR/curl_cffi"

if [ ! -d "$SOURCES_DIR/curl-impersonate/.git" ]; then
  require_command git
  log "cloning curl-impersonate"
  git clone --depth 1 --branch "$CURL_IMPERSONATE_REF" \
    https://github.com/lexiforest/curl-impersonate.git \
    "$SOURCES_DIR/curl-impersonate"
else
  log "curl-impersonate already fetched"
fi

log "sources are ready in $SOURCES_DIR"
