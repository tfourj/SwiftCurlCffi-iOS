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
  version_key=$4
  download_dir="$SOURCES_DIR/pypi"
  project_download_dir="$download_dir/$project"

  if [ -d "$target" ]; then
    log "$project already fetched"
    resolved_version=$(version_from_source_dir "$target" || true)
    if [ -n "$resolved_version" ]; then
      record_resolved_version "$version_key" "$resolved_version"
    fi
    return
  fi

  if [ "$version" = "latest" ]; then
    spec="$project"
    log "downloading latest $project"
  else
    spec="$project==$version"
    log "downloading $spec"
  fi

  rm -rf "$project_download_dir"
  mkdir -p "$project_download_dir" "$target.tmp"
  prerelease_args=""
  if [ "$project" = "curl-cffi" ] && [ "$CURL_CFFI_ALLOW_PRERELEASES" = "1" ]; then
    prerelease_args="--pre"
  fi

  "$HOST_PYTHON" -m pip download \
    --no-binary :all: \
    --no-deps \
    $prerelease_args \
    --dest "$project_download_dir" \
    "$spec"

  archive=$(find "$project_download_dir" -maxdepth 1 -name "*.tar.gz" -print | grep "/$project-" | head -1 || true)
  if [ -z "$archive" ] && [ "$project" = "curl-cffi" ]; then
    archive=$(find "$project_download_dir" -maxdepth 1 -name "curl_cffi-*.tar.gz" -print | head -1 || true)
  fi
  [ -n "$archive" ] || die "downloaded sdist not found for $project"
  resolved_version=$(version_from_sdist_archive "$archive" || true)
  [ -n "$resolved_version" ] || die "unable to resolve downloaded version for $project"

  tar -xzf "$archive" -C "$target.tmp" --strip-components 1
  mv "$target.tmp" "$target"
  record_resolved_version "$version_key" "$resolved_version"
  log "$project resolved version: $resolved_version"
}

download_and_extract \
  "libffi-$LIBFFI_VERSION" \
  "https://github.com/libffi/libffi/releases/download/v$LIBFFI_VERSION/libffi-$LIBFFI_VERSION.tar.gz" \
  "$SOURCES_DIR/libffi"

download_pypi_sdist "cffi" "$CFFI_VERSION" "$SOURCES_DIR/cffi" "CFFI_RESOLVED_VERSION"
download_pypi_sdist "curl-cffi" "$CURL_CFFI_VERSION" "$SOURCES_DIR/curl_cffi" "CURL_CFFI_RESOLVED_VERSION"

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
